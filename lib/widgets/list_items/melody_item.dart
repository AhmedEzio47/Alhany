import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/services/payment_service.dart';
import 'package:dubsmash/services/sqlite_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:stripe_payment/stripe_payment.dart';

class MelodyItem extends StatefulWidget {
  final Melody melody;
  final BuildContext context;
  final bool isRounded;
  final double imageSize;
  final double padding;
  MelodyItem({Key key, this.melody, this.context, this.isRounded = true, this.imageSize = 50, this.padding = 8})
      : super(key: key);

  @override
  _MelodyItemState createState() => _MelodyItemState();
}

class _MelodyItemState extends State<MelodyItem> {
  User _author;
  bool _isFavourite = false;

  List<String> choices;

  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    if (widget.melody.isSong) {
      choices = [
        language(en: 'Edit lyrics', ar: 'تعديل الكلمات'),
        language(en: 'Edit Image', ar: 'تعديل الصورة'),
        language(en: 'Edit Name', ar: 'تعديل الإسم'),
        language(en: 'Delete', ar: 'حذف')
      ];
    } else {
      choices = [
        language(en: 'Edit Image', ar: 'تعديل الصورة'),
        language(en: 'Edit Name', ar: 'تعديل الإسم'),
        language(en: 'Delete', ar: 'حذف')
      ];
    }
    if (widget.melody.authorId != null) {
      getAuthor();
    }
    super.initState();
    PaymentService.configureStripePayment();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await isFavourite();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.melody.authorId);
    setState(() {
      _author = author;
    });
  }

  isFavourite() async {
    bool isFavourite =
        (await usersRef.document(Constants.currentUserID).collection('favourites').document(widget.melody.id).get())
            .exists;

    setState(() {
      _isFavourite = isFavourite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.padding),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.4),
          borderRadius: widget.isRounded ? BorderRadius.circular(20.0) : null,
        ),
        child: ListTile(
          leading: CachedImage(
            width: widget.imageSize,
            height: widget.imageSize,
            imageUrl: widget.melody.imageUrl,
            imageShape: BoxShape.rectangle,
            defaultAssetImage: Strings.default_melody_image,
          ),
          title: Text(widget.melody.name),
          subtitle: Text(_author?.name ?? widget.melody.singer ?? ''),
          trailing: InkWell(
            onTap: () async {
              _isFavourite
                  ? await DatabaseService.deleteMelodyFromFavourites(widget.melody.id)
                  : await DatabaseService.addMelodyToFavourites(widget.melody.id);

              await isFavourite();
            },
            child: Container(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    _isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: MyColors.accentColor,
                  ),
                  Constants.isAdmin
                      ? PopupMenuButton<String>(
                          color: MyColors.accentColor,
                          elevation: 0,
                          onCanceled: () {
                            print('You have not chosen anything');
                          },
                          tooltip: 'This is tooltip',
                          onSelected: _select,
                          itemBuilder: (BuildContext context) {
                            return choices.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice,
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList();
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () async {
                              _downloadMelody();
                            },
                            child: Icon(
                              Icons.file_download,
                              color: MyColors.accentColor,
                            ),
                          ),
                        )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(String value) async {
    switch (value) {
      case 'Edit Image':
        await editImage();
        break;

      case 'Edit Name':
        await editName();
        break;

      case 'Delete':
        await deleteMelody();
        break;
      case 'Edit lyrics':
        Navigator.of(context).pushNamed('/lyrics-editor');
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.melody.imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(widget.melody.imageUrl);
      await storageRef.child('/melodies_images/$fileName').delete();
    }

    String url = await AppUtil.uploadFile(image, context, '/melodies_images/${widget.melody.id}$ext');
    await melodiesRef.document(widget.melody.id).updateData({'image_url': url});
    AppUtil.showToast('Image updated!');
  }

  editName() async {
    setState(() {
      _nameController.text = widget.melody.name;
    });
    Navigator.of(context).push(CustomModal(
        child: Container(
      height: 200,
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'New name'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) {
                AppUtil.showToast('Please enter a name');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              await melodiesRef.document(widget.melody.id).updateData({
                'name': _nameController.text,
                'search': searchList(_nameController.text),
              });
              AppUtil.showToast('Name Updated');
              Navigator.of(context).pop();
            },
            color: MyColors.primaryColor,
            child: Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    )));
  }

  deleteMelody() async {
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this melody?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          if (widget.melody.imageUrl != null) {
            String fileName = await AppUtil.getStorageFileNameFromUrl(widget.melody.imageUrl);
            await storageRef.child('/melodies_images/$fileName').delete();
          }
          if (widget.melody.audioUrl != null) {
            String fileName = await AppUtil.getStorageFileNameFromUrl(widget.melody.audioUrl);
            if (widget.melody.isSong) {
              await storageRef.child('/songs/$fileName').delete();
            } else {
              await storageRef.child('/melodies/$fileName').delete();
            }
          }
          if (widget.melody.levelUrls != null) {
            for (String url in widget.melody.levelUrls.values) {
              String fileName = await AppUtil.getStorageFileNameFromUrl(url);

              await storageRef.child('/melodies/$fileName').delete();
            }
          }
          await melodiesRef.document(widget.melody.id).delete();
          AppUtil.showToast('Deleted!');
          Navigator.of(context).pop();
          // AppUtil.showAlertDialog(
          //     context: context,
          //     message: 'Do you want to delete records on this melody too?',
          //     firstBtnText: 'Yes',
          //     firstFunc: () async {
          //       AppUtil.showLoader(context);
          //       List<Record> records = await DatabaseService.getRecordsByMelody(widget.melody.id);
          //       for (Record record in records) {
          //         String fileName = await AppUtil.getStorageFileNameFromUrl(record.audioUrl);
          //         await storageRef.child('/records/${widget.melody.id}/$fileName').delete();
          //         await recordsRef.document(record.id).delete();
          //       }
          //       Navigator.of(context).pop();
          //     },
          //     secondBtnText: 'No',
          //     secondFunc: () {
          //       Navigator.of(context).pop();
          //     });
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }

  void _downloadMelody() async {
    Token token = Token();
    if (widget.melody.price == null || widget.melody.price == '0') {
      token.tokenId = 'free';
    } else {
      DocumentSnapshot doc =
          await usersRef.document(Constants.currentUserID).collection('downloads').document(widget.melody.id).get();
      bool alreadyDownloaded = doc.exists;
      print('alreadyDownloaded: $alreadyDownloaded');

      if (!alreadyDownloaded) {
        token = await PaymentService.nativePayment(widget.melody.price);
        print(token.tokenId);
      } else {
        token.tokenId = 'already purchased';
        AppUtil.showToast('already purchased');
      }
    }
    if (token.tokenId != null) {
      AppUtil.showLoader(context);
      await AppUtil.createAppDirectory();
      String path;
      if (widget.melody.audioUrl != null) {
        path = await AppUtil.downloadFile(widget.melody.audioUrl, encrypt: true);
      } else {
        path = await AppUtil.downloadFile(widget.melody.levelUrls.values.elementAt(0), encrypt: true);
      }

      Melody melody = Melody(
          id: widget.melody.id,
          authorId: widget.melody.authorId,
          description: widget.melody.description,
          imageUrl: widget.melody.imageUrl,
          name: widget.melody.name,
          audioUrl: path);
      if (MelodySqlite.getMelodyWithId(widget.melody.id) == null) {
        await MelodySqlite.insert(melody);
        await usersRef
            .document(Constants.currentUserID)
            .collection('downloads')
            .document(widget.melody.id)
            .setData({'timestamp': FieldValue.serverTimestamp()});
        Navigator.of(context).pop();
        AppUtil.showToast('Downloaded!');
      } else {
        Navigator.of(context).pop();
        AppUtil.showToast('Already downloaded!');
      }
    }
  }
}

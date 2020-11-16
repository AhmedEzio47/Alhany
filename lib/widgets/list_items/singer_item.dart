import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/singer_model.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class SingerItem extends StatefulWidget {
  final Singer singer;

  const SingerItem({Key key, this.singer}) : super(key: key);
  @override
  _SingerItemState createState() => _SingerItemState();
}

class _SingerItemState extends State<SingerItem> {
  var choices = ['Edit Image', 'Edit Name', 'Delete'];

  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white.withOpacity(.4),
      ),
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(vertical: 8),
      width: MediaQuery.of(context).size.width,
      height: 70,
      child: ListTile(
        onTap: () {
          Navigator.of(context).pushNamed('/songs-page', arguments: {'singer': widget.singer});
        },
        title: Text(
          widget.singer.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: CachedImage(
          imageUrl: widget.singer.imageUrl,
          defaultAssetImage: Strings.default_profile_image,
          imageShape: BoxShape.rectangle,
          height: 50,
          width: 50,
        ),
        trailing: Constants.isAdmin
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
            : null,
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
        await deleteSinger();
        break;
    }
  }

  editImage() async {
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);

    if (widget.singer.imageUrl != null) {
      String fileName = await AppUtil.getStorageFileNameFromUrl(widget.singer.imageUrl);
      await storageRef.child('/singers_images/$fileName').delete();
    }

    String url = await AppUtil().uploadFile(image, context, '/singers_images/${widget.singer.id}$ext');
    await singersRef.document(widget.singer.id).updateData({'image_url': url});
    AppUtil.showToast('Image updated!');
  }

  editName() async {
    setState(() {
      _nameController.text = widget.singer.name;
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
              await singersRef.document(widget.singer.id).updateData({
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

  deleteSinger() async {
    AppUtil.showAlertDialog(
        context: context,
        message: 'Are you sure you want to delete this singer?',
        firstBtnText: 'Yes',
        firstFunc: () async {
          Navigator.of(context).pop();
          AppUtil.showLoader(context);
          if (widget.singer.imageUrl != null) {
            String fileName = await AppUtil.getStorageFileNameFromUrl(widget.singer.imageUrl);
            await storageRef.child('/singers_images/$fileName').delete();
          }
          await singersRef.document(widget.singer.id).delete();
          AppUtil.showToast('Deleted!');
          Navigator.of(context).pop();
        },
        secondBtnText: 'No',
        secondFunc: () {
          Navigator.of(context).pop();
        });
  }
}

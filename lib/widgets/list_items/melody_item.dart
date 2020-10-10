import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/constants/constants.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:dubsmash/models/user_model.dart';
import 'package:dubsmash/services/database_service.dart';
import 'package:dubsmash/widgets/cached_image.dart';
import 'package:flutter/material.dart';

class MelodyItem extends StatefulWidget {
  final Melody melody;

  MelodyItem({Key key, this.melody}) : super(key: key);

  @override
  _MelodyItemState createState() => _MelodyItemState();
}

class _MelodyItemState extends State<MelodyItem> {
  User _author;
  bool _isFavourite = false;

  @override
  void initState() {
    getAuthor();
    isFavourite();
    super.initState();
  }

  getAuthor() async {
    User author = await DatabaseService.getUserWithId(widget.melody.authorId);
    setState(() {
      _author = author;
    });
  }

  isFavourite() async {
    bool isFavourite = (await usersRef
            .document(Constants.currentUserID)
            .collection('favourites')
            .document(widget.melody.id)
            .get())
        .exists;

    setState(() {
      _isFavourite = isFavourite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 70,
        color: Colors.white.withOpacity(.4),
        child: ListTile(
          leading: CachedImage(
            width: 50,
            height: 50,
            imageUrl: widget.melody.imageUrl,
            imageShape: BoxShape.rectangle,
            defaultAssetImage: Strings.default_melody_image,
          ),
          title: Text(widget.melody.name),
          subtitle: Text(_author?.name ?? ''),
          trailing: InkWell(
            onTap: () async {
              _isFavourite
                  ? await DatabaseService.deleteMelodyFromFavourites(
                      widget.melody.id)
                  : await DatabaseService.addMelodyToFavourites(
                      widget.melody.id);

              isFavourite();
            },
            child: Icon(
              _isFavourite ? Icons.favorite : Icons.favorite_border,
              color: MyColors.accentColor,
            ),
          ),
        ),
      ),
    );
  }
}

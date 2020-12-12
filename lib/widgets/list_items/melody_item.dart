import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/user_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/payment_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:flutter/material.dart';

class MelodyItem extends StatefulWidget {
  final Melody melody;
  final BuildContext context;
  final bool isRounded;
  final double imageSize;
  final double padding;
  MelodyItem({Key key, this.melody, this.context, this.isRounded = true, this.imageSize = 50, this.padding = 4.0})
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
    if (widget.melody.authorId != null) {
      getAuthor();
    }
    super.initState();
    PaymentService.initPayment();
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
          trailing: widget.melody?.isSong ?? false
              ? InkWell(
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
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

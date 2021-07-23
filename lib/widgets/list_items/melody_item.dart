import 'package:Alhany/app_util.dart';
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
  final bool showPrice;
  final bool showFavBtn;
  MelodyItem(
      {Key key,
      this.melody,
      this.context,
      this.isRounded = true,
      this.imageSize = 50,
      this.showPrice = true,
      this.showFavBtn = true,
      this.padding = 4.0})
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
    if (mounted) {
      setState(() {
        _author = author;
      });
    }
  }

  isFavourite() async {
    bool isFavourite = (await usersRef
            .doc(Constants.currentUserID)
            .collection('favourites')
            .doc(widget.melody.id)
            .get())
        .exists;

    if (mounted) {
      setState(() {
        _isFavourite = isFavourite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.padding),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
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
          title: Text(widget.melody.name ?? '',
              style: TextStyle(color: MyColors.textLightColor)),
          subtitle: (_author?.name != null || widget.melody.singer != null)
              ? Text(
                  _author?.name ?? widget.melody.singer ?? '',
                  style: TextStyle(color: MyColors.textLightColor),
                )
              : Text(''),
          trailing: (widget.melody?.songUrl != null ?? false) &&
                  widget.showFavBtn
              ? InkWell(
                  onTap: () =>
                      AppUtil.executeFunctionIfLoggedIn(context, () async {
                    if (_isFavourite)
                      await DatabaseService.deleteMelodyFromFavourites(
                          widget.melody.id);
                    else if (Constants.currentUser.boughtSongs != null &&
                            Constants.currentUser.boughtSongs
                                .contains(widget.melody.id) ||
                        (widget.melody.price == '0' ||
                            widget.melody.price == null)) {
                      print('Song can be added to favorites');
                      await DatabaseService.addMelodyToFavourites(
                          widget.melody.id);
                    } else {
                      AppUtil.showToast(language(
                          ar: 'قم بشراء الأغنية أولا', en: 'Buy song first'));
                    }

                    await isFavourite();
                  }),
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
              : widget.melody.price != null && widget.showPrice
                  ? Text(
                      '${widget.melody.price} \$',
                      style: TextStyle(color: MyColors.textLightColor),
                    )
                  : null,
        ),
      ),
    );
  }
}

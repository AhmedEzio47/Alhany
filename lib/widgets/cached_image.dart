import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxShape imageShape;
  final double width;
  final double height;
  final String defaultAssetImage;
  final BoxFit assetFit;

  const CachedImage({
    Key key,
    this.imageUrl,
    this.imageShape,
    this.width,
    this.height,
    this.defaultAssetImage,
    this.assetFit = BoxFit.cover,
  }) : super(key: key);

  @override
  _CachedImageState createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  @override
  Widget build(BuildContext context) {
    return _cacheRoundedImage(widget.imageUrl, widget.imageShape, widget.width,
        widget.height, widget.defaultAssetImage, widget.assetFit);
  }

  Widget _cacheRoundedImage(String imageUrl, BoxShape boxShape, double width,
      double height, String defaultAssetImage, BoxFit fit) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: boxShape,
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  shape: boxShape,
                  image: DecorationImage(
                      image: imageProvider, fit: widget.assetFit),
                ),
              ),
              placeholder: (context, loggedInProfileImageURL) => Center(
                  child: Image.asset(
                defaultAssetImage,
                fit: fit,
                height: height,
                width: width,
              )),
              errorWidget: (context, loggedInProfileImageURL, error) =>
                  Icon(Icons.error),
            )
          : Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: boxShape,
                image: DecorationImage(
                    image: AssetImage(defaultAssetImage), fit: BoxFit.cover),
              ),
            ),
    );
  }
}

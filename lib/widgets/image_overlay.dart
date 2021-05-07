import 'dart:io';

import 'package:Alhany/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageOverlay extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final List<IconData> btnIcons;
  final List<Function> btnFunctions;

  const ImageOverlay(
      {Key? key,
      this.imageUrl,
      this.imageFile,
      required this.btnIcons,
      required this.btnFunctions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imageOverlay(
        context,
        imageUrl != null
            ? PhotoView(
                imageProvider: NetworkImage(imageUrl!),
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.contained * 2,
                enableRotation: true,
                loadingChild: Center(child: CircularProgressIndicator()),
                backgroundDecoration:
                    BoxDecoration(color: Colors.transparent.withOpacity(.3)),
              )
            : imageFile != null
                ? PhotoView(
                    imageProvider: FileImage(imageFile!),
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.contained * 2,
                    enableRotation: true,
                    loadingChild: Center(child: CircularProgressIndicator()),
                    backgroundDecoration: BoxDecoration(
                        color: Colors.transparent.withOpacity(.3)),
                  )
                : null,
        this.btnIcons,
        this.btnFunctions);
  }
}

imageOverlay(BuildContext context, Widget? child, List<IconData> btnIcons,
    List<Function> btnFunctions) {
  return Scaffold(
    appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        actions: btnList(btnIcons, btnFunctions)),
    body: Stack(
      children: <Widget>[
        if (child != null) child,
      ],
    ),
  );
}

void handleClick(String value) {}

List<Widget> btnList(List<IconData> btnIcons, List<Function> btnFunctions) {
  List<Widget> btnList = [];
  for (int i = 0; i < btnIcons.length; i++) {
    btnList.add(IconButton(
      icon: Icon(
        btnIcons[i],
        color: MyColors.iconLightColor,
      ),
      onPressed: () => btnFunctions[i](),
    ));
  }

  return btnList;
}

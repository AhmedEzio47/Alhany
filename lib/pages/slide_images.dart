import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/slide_image.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/cached_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class SlideImages extends StatefulWidget {
  @override
  _SlideImagesState createState() => _SlideImagesState();
}

class _SlideImagesState extends State<SlideImages> {
  List<SlideImage> _slideImages = [];
  List<String> _choices = ['الصفحة الشخصية', 'صفحة الفنان'];
  String? _chosenPage;

  @override
  void initState() {
    setState(() {
      _chosenPage = _choices[0];
    });
    getSlideImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Star Slide Images'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<dynamic>(
              hint: Text('Singer'),
              value: _chosenPage,
              onChanged: (text) async {
                setState(() {
                  _chosenPage = text;
                });
                getSlideImages();
              },
              items: (_choices).map<DropdownMenuItem<dynamic>>((dynamic value) {
                return DropdownMenuItem<dynamic>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: _slideImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        CachedImage(
                          imageUrl: _slideImages[index].url!,
                          height: 200,
                          imageShape: BoxShape.rectangle,
                          width: MediaQuery.of(context).size.width,
                          defaultAssetImage: Strings.default_cover_image,
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black45),
                                child: IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    AppUtil.showAlertDialog(
                                        context: context,
                                        message:
                                            'Are you sure to delete this post?',
                                        firstBtnText: 'Yes',
                                        firstFunc: () async {
                                          AppUtil.showLoader(context);
                                          await DatabaseService
                                              .deleteSlideImage(
                                                  _slideImages[index]);
                                          Navigator.of(context).pop();
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                                  '/slide-images');
                                        },
                                        secondBtnText: 'No',
                                        secondFunc: () =>
                                            Navigator.of(context).pop());
                                  },
                                  alignment: Alignment.center,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addImage,
        child: Icon(Icons.add),
      ),
    );
  }

  addImage() async {
    String id = randomAlphaNumeric(20);
    File image = await AppUtil.pickImageFromGallery();
    String ext = path.extension(image.path);
    AppUtil.showLoader(context);
    String url =
        await AppUtil().uploadFile(image, context, '/slide_images/$id$ext');
    slideImagesRef.doc(id).set({
      'url': url,
      'page': _chosenPage,
      'timestamp': FieldValue.serverTimestamp()
    });
    AppUtil.showToast('Uploaded');
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed('/slide-images');
  }

  getSlideImages() async {
    List<SlideImage> slideImages =
        await DatabaseService.getSlideImages(_chosenPage!);
    setState(() {
      _slideImages = slideImages;
    });
  }
}

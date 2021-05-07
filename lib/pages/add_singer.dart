import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class AddSingerPage extends StatefulWidget {
  @override
  _AddSingerPageState createState() => _AddSingerPageState();
}

class _AddSingerPageState extends State<AddSingerPage> {
  File? _singerImage;
  File? _coverImage;

  TextEditingController _singerController = TextEditingController();
  List<String> _categories = [];

  getCategories() async {
    _categories = [];
    QuerySnapshot categoriesSnapshot = await categoriesRef.get();
    for (DocumentSnapshot doc in categoriesSnapshot.docs) {
      setState(() {
        _categories.add(doc.data()?['name']);
      });
    }
  }

  @override
  void initState() {
    getCategories();
    super.initState();
  }

  String? _category;
  TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                  onTap: () async {
                    await addCategory();
                  },
                  child: Center(child: Text('Add Category'))),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              height: 400,
              color: Colors.white,
              alignment: Alignment.center,
              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Stack(
                    children: [
                      Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                          ),
                          child: _coverImage == null
                              ? InkWell(
                                  onTap: () async {
                                    File? image =
                                        await AppUtil.pickImageFromGallery();
                                    setState(() {
                                      _coverImage = image;
                                    });
                                  },
                                  child: Image.asset(
                                    Strings.default_cover_image,
                                    fit: BoxFit.cover,
                                  ))
                              : Image.file(_coverImage!)),
                      Positioned.fill(
                          child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: _singerImage == null
                                  ? InkWell(
                                      onTap: () async {
                                        File? image = await AppUtil
                                            .pickImageFromGallery();
                                        setState(() {
                                          _singerImage = image;
                                        });
                                      },
                                      child: CircleAvatar(
                                          backgroundImage: AssetImage(
                                              Strings.default_profile_image)))
                                  : CircleAvatar(
                                      backgroundImage: FileImage(_singerImage!),
                                    )),
                        ),
                      ))
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 10),
                    child: TextField(
                      controller: _singerController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(hintText: 'Singer name'),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    flex: 8,
                    child: DropdownButton<dynamic>(
                      hint: Text('Category'),
                      value: _category,
                      onChanged: (text) {
                        setState(() {
                          _category = text;
                        });
                      },
                      items: (_categories)
                          .map<DropdownMenuItem<dynamic>>((dynamic value) {
                        return DropdownMenuItem<dynamic>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  RaisedButton(
                    onPressed: () async {
                      if (_singerController.text.trim().isEmpty) {
                        AppUtil.showToast('Please enter a name');
                        return;
                      }
                      Navigator.of(context).pop();
                      String? imageUrl;
                      String? coverUrl;
                      String id = randomAlphaNumeric(20);

                      if (_singerImage != null) {
                        String ext = path.extension(_singerImage!.path);
                        imageUrl = await AppUtil().uploadFile(
                            _singerImage, context, '/singers_images/$id$ext');
                      }
                      if (_coverImage != null) {
                        String ext = path.extension(_coverImage!.path);
                        coverUrl = await AppUtil().uploadFile(
                            _coverImage, context, '/singers_covers/$id$ext');
                      }
                      if (imageUrl != null && _coverImage != null)
                        await singersRef.doc(id).set({
                          'name': _singerController.text,
                          'category': _category,
                          'image_url': imageUrl,
                          'cover_url': coverUrl,
                          'songs': 0,
                          'melodies': 0,
                          'search': searchList(_singerController.text),
                        });
                      AppUtil.showToast('Singer added');
                      Navigator.of(context).pop();
                    },
                    color: MyColors.primaryColor,
                    child: Text(
                      'Add Singer',
                      style: TextStyle(color: MyColors.textLightColor),
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

  addCategory() async {
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
              controller: _categoryController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'New category'),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          RaisedButton(
            onPressed: () async {
              if (_categoryController.text.trim().isEmpty) {
                AppUtil.showToast('Please enter a category');
                return;
              }
              Navigator.of(context).pop();
              AppUtil.showLoader(context);
              int order = await DatabaseService.getMaxCategoryOrder();

              await categoriesRef.add({
                'name': _categoryController.text,
                'order': order,
                'search': searchList(_categoryController.text),
              });
              //AppUtil.showToast(language(en: Strings.en_updated, ar: Strings.ar_updated));
              Navigator.of(context).pop();
            },
            color: MyColors.primaryColor,
            child: Text(
              language(en: Strings.en_add, ar: Strings.ar_add),
              style: TextStyle(color: MyColors.textLightColor),
            ),
          )
        ],
      ),
    )));
    getCategories();
  }
}

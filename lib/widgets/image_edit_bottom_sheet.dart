import 'package:Alhany/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_inkwell.dart';

class ImageEditBottomSheet {
  var source;
  Widget optionIcon(BuildContext context) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          openBottomSheet(context);
        },
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_drop_down),
        ));
  }

  Future openBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: EdgeInsets.only(top: 5, bottom: 0),
            height: MediaQuery.of(context).size.height * (.22),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: MyColors.darkPrimaryColor.withOpacity(.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _postOptions(context));
      },
    );
  }

  Widget _postOptions(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: MyColors.darkPrimaryColor.withOpacity(.9),
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        _widgetBottomSheetRow(
            context,
            Icon(
              Icons.camera_alt,
              color: MyColors.primaryColor,
            ),
            text: 'Camera', onPressed: () {
          source = ImageSource.camera;
          Navigator.of(context).pop();
        }),
        Divider(
          height: 1,
          color: Colors.white,
        ),
        _widgetBottomSheetRow(
            context,
            Icon(
              Icons.image,
              color: MyColors.primaryColor,
            ),
            text: 'Gallery', onPressed: () async {
          source = ImageSource.gallery;
          Navigator.of(context).pop();
        }),
      ],
    );
  }

  Widget _widgetBottomSheetRow(BuildContext context, Icon icon,
      {required String text, Function? onPressed}) {
    return Expanded(
      child: customInkWell(
        context: context,
        onPressed: () {
          if (onPressed != null)
            onPressed();
          else {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              icon,
              SizedBox(
                width: 15,
              ),
              Text(
                text,
                style: TextStyle(
                  color: MyColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

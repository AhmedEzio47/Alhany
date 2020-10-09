import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';

import 'constants/colors.dart';
import 'constants/constants.dart';

saveToken() async {
  String token = await FirebaseMessaging().getToken();
  usersRef
      .document(Constants.currentUserID)
      .collection('tokens')
      .document(token)
      .setData({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
}

List<String> searchList(String text) {
  List<String> list = [];
  for (int i = 1; i <= text.length; i++) {
    list.add(text.substring(0, i).toLowerCase());
  }
  return list;
}

class AppUtil {
  static void showAlertDialog(
      {@required BuildContext context,
      String heading,
      String message,
      String firstBtnText,
      String secondBtnText,
      Function firstFunc,
      Function secondFunc}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: heading != null ? Text(heading) : null,
            content: Text(message),
            actions: <Widget>[
              MaterialButton(
                onPressed: firstFunc,
                child: Text(firstBtnText),
              ),
              secondBtnText != null
                  ? MaterialButton(
                      onPressed: secondFunc,
                      child: Text(secondBtnText),
                    )
                  : Container(),
            ],
          );
        });
  }

  static showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: MyColors.lightPrimaryColor,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static Future<File> chooseAudio() async {
    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: [
      'mp3',
      'wav',
    ]);

    if (result != null) {
      File file = File(result.files.single.path);
      return file;
    }

    return null;
  }

  static Future<String> uploadFile(
      File file, BuildContext context, String path) async {
    if (file == null) return '';

    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(path);
    print('storage path: $path');
    StorageUploadTask uploadTask;

    uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    String url = await storageReference.getDownloadURL();

    return url;
  }

  static Future<String> downloadFile(String url) async {
    var response = await get(url);
    var firstPath = '/sdcard/download/';
    var contentDisposition = response.headers['content-disposition'];
    String fileName = contentDisposition
        .split('filename*=utf-8')
        .last
        .replaceAll(RegExp('%20'), ' ')
        .replaceAll(RegExp('%2C|\''), '');
    String filePathAndName = firstPath + fileName;
    filePathAndName = filePathAndName.replaceAll(' ', '_');
    File file = new File(filePathAndName);
    file.writeAsBytesSync(response.bodyBytes);

    return filePathAndName;
  }
}

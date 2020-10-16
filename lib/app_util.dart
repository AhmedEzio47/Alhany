import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/widgets/custom_modal.dart';
import 'package:dubsmash/widgets/flip_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'constants/colors.dart';

// saveToken() async {
//   String token = await FirebaseMessaging().getToken();
//   usersRef
//       .document(Constants.currentUserID)
//       .collection('tokens')
//       .document(token)
//       .setData({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
// }

List<String> searchList(String text) {
  List<String> list = [];
  for (int i = 1; i <= text.length; i++) {
    list.add(text.substring(0, i).toLowerCase());
  }
  return list;
}

class AppUtil {
  static showAlertDialog(
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
        backgroundColor: MyColors.accentColor,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static Future<File> chooseAudio() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [
      'mp3',
      'wav',
    ]);

    if (result != null) {
      File file = File(result.files.single.path);
      return file;
    }

    return null;
  }

  static Future<File> pickImageFromGallery() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [
      'jpg',
      'png',
    ]);

    if (result != null) {
      File file = File(result.files.single.path);
      return file;
    }

    return null;
  }

  static Future<String> uploadFile(File file, BuildContext context, String path) async {
    if (file == null) return '';

    StorageReference storageReference = FirebaseStorage.instance.ref().child(path);
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
    var firstPath = appTempDirectoryPath;
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

  static createAppDirectory() async {
    if (!(await Directory('sdcard/download/$appName').exists())) {
      final dir = await Directory('sdcard/download/$appName').create();
      appTempDirectoryPath = dir.path + '/';
      print('appTempDirectoryPath: $appTempDirectoryPath');
    } else {
      appTempDirectoryPath = 'sdcard/download/$appName/';
    }
  }

  static Future<File> takePhoto() async {
    File image = await ImagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
    return image;
  }

  static showLoader(BuildContext context) {
    Navigator.of(context).push(CustomModal(
        child: FlipLoader(
            loaderBackground: MyColors.primaryColor,
            iconColor: Colors.white,
            icon: Icons.music_note,
            animationType: "full_flip")));
  }

  static String formatTimestamp(Timestamp timestamp) {
    if (timestamp == null) return '';

    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = 'A minute ago';
      } else {
        time = diff.inMinutes.toString() + ' minutes ago';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = 'An hour ago';
      } else {
        time = diff.inHours.toString() + ' hours ago';
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    } else {
      if (diff.inDays == 7) {
        time = 'A WEEK AGO';
      } else {
        /// Show in Format => 21-05-2019 10:59 AM
        final df = new DateFormat('dd-MM-yyyy hh:mm a');
        time = df.format(date);
      }
    }

    return time;
  }
}

import 'dart:io';

import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:Alhany/models/record_model.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/encryption_service.dart';
import 'package:Alhany/services/notification_handler.dart';
import 'package:Alhany/services/share_link.dart';
import 'package:Alhany/widgets/custom_modal.dart';
import 'package:Alhany/widgets/flip_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/colors.dart';
import 'constants/constants.dart';
import 'models/user_model.dart' as user_model;

saveToken() async {
  if (Constants.currentUserID == null) return;
  String token;
  if (Platform.isIOS || Platform.isMacOS) {
    token = await FirebaseMessaging.instance.getAPNSToken();
  } else {
    token = await FirebaseMessaging.instance.getToken();
  }
  usersRef
      .doc(Constants.currentUserID)
      .collection('tokens')
      .doc(token)
      .set({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
}

List<String> searchList(String text) {
  if (text == null || text.isEmpty) return null;
  List<String> list = [];
  for (int i = 1; i <= text.length; i++) {
    list.add(text.substring(0, i).toLowerCase());
  }
  return list;
}

class AppUtil with ChangeNotifier {
  static double progress;
  static bool fullScreenPage = false;
  static Record fullscreenRecord;
  static user_model.User fullscreenSinger;
  static Melody fullscreenMelody;

  goToFullscreen(Record record, user_model.User user, Melody melody) {
    fullscreenRecord = record;
    fullscreenSinger = user;
    fullscreenMelody = melody;
    fullScreenPage = true;
    notifyListeners();
  }

  goToHome() {
    fullScreenPage = false;
    notifyListeners();
  }

  static void showFixedSnackBar(BuildContext context,
      GlobalKey<ScaffoldState> _scaffoldKey, String text) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: MyColors.textDarkColor,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ),
      backgroundColor: MyColors.accentColor,
      duration: Duration(minutes: 5),
    ));
  }

  static showAlertDialog({
    @required BuildContext context,
    String heading,
    String message,
    String firstBtnText,
    String secondBtnText,
    String thirdBtnText,
    Function firstFunc,
    Function secondFunc,
    Function thirdFunc,
  }) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: heading != null ? Text(heading) : null,
            content: Text(
              message,
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              MaterialButton(
                onPressed: firstFunc,
                child: Text(
                  firstBtnText,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              secondBtnText != null
                  ? MaterialButton(
                      onPressed: secondFunc,
                      child: Text(
                        secondBtnText,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : Container(),
              thirdBtnText != null
                  ? MaterialButton(
                      onPressed: thirdFunc,
                      child: Text(
                        thirdBtnText,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : Container(),
            ],
          );
        });
  }

  static deleteFiles() async {
    String initialPath = '${(await getApplicationDocumentsDirectory()).path}/';
    if ((await Directory('$initialPath' + 'temp').exists())) {
      print('Deleting old temp files!');
      final dir = Directory('$initialPath' + 'temp');
      await dir.delete(recursive: true);
      appTempDirectoryPath = '';
    }
    if (appTempDirectoryPath != '' && appTempDirectoryPath != null) {
      print('deleting temp files');
      final dir = Directory(appTempDirectoryPath);
      await dir.delete(recursive: true);
      appTempDirectoryPath = '';
      //await AppUtil.createAppDirectory();
    }
  }

  static showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: MyColors.accentColor,
        textColor: MyColors.primaryColor,
        fontSize: 16.0);
  }

  static Future chooseAudio({bool multiple = false}) async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
        ],
        allowMultiple: multiple);

    if (result != null) {
      if (multiple) {
        List<File> files = [];
        result.files.forEach((file) {
          files.add(File(file.path));
        });
        return files;
      } else {
        File file = File(result.files.single.path);
        return file;
      }
    }

    return null;
  }

  static Future chooseVideo({bool multiple = false}) async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'avi',
        ],
        allowMultiple: multiple);

    if (result != null) {
      if (multiple) {
        List<File> files = [];
        result.files.forEach((file) {
          files.add(File(file.path));
        });
        return files;
      } else {
        File file = File(result.files.single.path);
        return file;
      }
    }

    return null;
  }

  static Future<File> pickImageFromGallery() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png'],
        allowCompression: true);

    if (result != null) {
      File file = File(result.files.single.path);
      return file;
    }

    return null;
  }

  static pickCompressedImageFromGallery() async {
    File pickedFile = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
    return pickedFile;
  }

  Future<String> uploadFile(
      File file, BuildContext context, String path) async {
    if (file == null) return '';

    Reference storageReference = FirebaseStorage.instance.ref().child(path);

    UploadTask uploadTask;
    uploadTask = storageReference.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      progress =
          snapshot.bytesTransferred.toDouble() / snapshot.totalBytes.toDouble();
      notifyListeners();
    }).onError((error) {
      // do something to handle error
    });
    await uploadTask;
    print('File Uploaded');
    String url = await storageReference.getDownloadURL();

    return url;
  }

  static Future<String> downloadFile(String url, {bool encrypt = false}) async {
    var firstPath = appTempDirectoryPath;

    var response = await get(url);
    var contentDisposition = response.headers['content-disposition'];
    String fileName =
        await getStorageFileNameFromContentDisposition(contentDisposition);
    String filePathAndName = firstPath + fileName;
    filePathAndName = filePathAndName.replaceAll(' ', '_');
    File file = new File(filePathAndName);
    await file.writeAsBytes(response.bodyBytes);
    if (encrypt) {
      return EncryptionService.encryptFile(file.path);
    }
    return filePathAndName;
  }

  static Future<String> getStorageFileNameFromUrl(String url) async {
    var response = await get(url);
    var contentDisposition = response.headers['content-disposition'];
    String fileName = contentDisposition
        .split('filename*=utf-8')
        .last
        .replaceAll(RegExp('%20'), ' ')
        .replaceAll(RegExp('%2C|\''), '');
    return fileName;
  }

  static Future<String> getStorageFileNameFromContentDisposition(
      var contentDisposition) async {
    String fileName = contentDisposition
        .split('filename*=utf-8')
        .last
        .replaceAll(RegExp('%20'), ' ')
        .replaceAll(RegExp('%2C|\''), '');
    return fileName;
  }

  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    appTempDirectoryPath = '${_appDocDir.path}/$folderName/';
    print('appTempDirectoryPath: $appTempDirectoryPath');
    //App Document Directory + folder name
    final Directory _appDocDirFolder = Directory('$appTempDirectoryPath');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  static createAppDirectory() async {
    String initialPath = '${(await getApplicationDocumentsDirectory()).path}/';
    if (!(await Directory('$initialPath' + 'temp').exists())) {
      final dir =
          await Directory('$initialPath' + 'temp').create(recursive: true);
      appTempDirectoryPath = dir.path + '/';
      print('appTempDirectoryPath: $appTempDirectoryPath');
    } else {
      appTempDirectoryPath = '$initialPath$appName/temp/';
      print('TempDir already exists: $appTempDirectoryPath');
    }
  }

  static Future<File> takePhoto() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    return image;
  }

  static showLoader(BuildContext context) {
    Navigator.of(context).push(CustomModal(
        child: FlipLoader(
            loaderBackground: MyColors.primaryColor,
            iconColor: MyColors.iconLightColor,
            icon: Icons.music_note,
            animationType: "full_flip")));
  }

  static String formatTimestamp(Timestamp timestamp) {
    if (timestamp == null) return '';

    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = 'a minute ago';
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
        time = 'a day ago';
      } else {
        time = diff.inDays.toString() + ' days ago';
      }
    } else {
      if (diff.inDays == 7) {
        time = 'a week ago';
      } else {
        /// Show in Format => 21-05-2019 10:59 AM
        final df = new DateFormat('dd-MM-yyyy hh:mm a');
        time = df.format(date);
      }
    }

    return time;
  }

  static String validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      AppUtil.showToast(
          language(en: "Email is Required", ar: 'يجب إدخال البريد الالكتروني'));
      return "Email is Required";
    } else if (!regExp.hasMatch(value)) {
      AppUtil.showToast(
          language(en: "Invalid Email", ar: 'البريد الإلكتروني غير صحيح'));
      return "Invalid Email";
    }
    return null;
  }

  static switchLanguage() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String language = sharedPreferences.getString('language');
    if (language == 'ar') {
      sharedPreferences.setString('language', 'en');
      Constants.language = 'en';
    } else {
      sharedPreferences.setString('language', 'ar');
      Constants.language = 'ar';
    }
  }

  static Future<String> getLanguage() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('language');
  }

  /// Format Time For Comments
  static String formatCommentsTimestamp(Timestamp timestamp) {
    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = '1m';
      } else {
        time = diff.inMinutes.toString() + 'm';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = '1h';
      } else {
        time = diff.inHours.toString() + 'h';
      }
    } else if (diff.inDays > 0) {
      if (diff.inDays == 1) {
        time = '1d';
      } else {
        time = diff.inDays.toString() + 'd';
      }
    }

    return time;
  }

  static checkIfContainsMention(String text, String recordId) async {
    text.split(' ').forEach((word) async {
      if (word.startsWith('@')) {
        user_model.User user =
            await DatabaseService.getUserWithUsername(word.substring(1));

        await NotificationHandler.sendNotification(
            user.id,
            'New mention',
            Constants.currentUser.username + ' mentioned you',
            recordId,
            'mention');
      }
    });
  }

  static Future<File> recordVideo(Duration maxDuration) async {
    File video = await ImagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
        preferredCameraDevice: CameraDevice.front);
    return video;
  }

  static sharePost(String postText, String imageUrl,
      {String recordId, String newsId}) async {
    var postLink = await DynamicLinks.createPostDynamicLink({
      'recordId': recordId,
      'newsId': newsId,
      'text': postText,
      'imageUrl': imageUrl
    });
    Share.share('Check out: $postText : $postLink');
    print('Check out: $postText : $postLink');
  }

  static setUserVariablesByFirebaseUser(User user) async {
    user_model.User loggedInUser =
        await DatabaseService.getUserWithId(user?.uid);

    user_model.User star = await DatabaseService.getUserWithId(Strings.starId);

    Constants.currentUser = loggedInUser;
    Constants.currentFirebaseUser = user;
    Constants.currentUserID = user?.uid;
    authStatus = AuthStatus.LOGGED_IN;
    Constants.startUser = star;
    Constants.isAdmin = (Constants.currentUserID == Strings.starId ||
        Constants.currentUserID == 'u4kxq4Rsa5Vq13chXWFrtzll12L2');
    Constants.isFacebookOrGoogleUser = false;
  }
}

String language({String ar, String en}) {
  if (Constants.language == 'ar') {
    return ar;
  } else {
    return en;
  }
}

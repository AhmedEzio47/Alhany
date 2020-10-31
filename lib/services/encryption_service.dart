import 'dart:io';
import 'dart:typed_data';

import 'package:aes_crypt/aes_crypt.dart';
import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';

class EncryptionService {
  // static encryptFile(File file) async {
  //   Encrypter encrypter = Encrypter(AES(Key.fromUtf8(Strings.encryption_key)));
  //   Uint8List uint8list = await file.readAsBytes();
  //   Encrypted encrypted = encrypter.encryptBytes(uint8list);
  //   file.writeAsBytesSync(encrypted.bytes);
  // }

  // static decryptFile(File encryptedFile) async {
  //   Encrypter encrypter = Encrypter(AES(Key.fromUtf8(Strings.encryption_key)));
  //   Encrypted encrypted = Encrypted.fromUtf8(encryptedFile.readAsStringSync());
  //   String decrypted = encrypter.decrypt(encrypted);
  //   encryptedFile.writeAsStringSync(decrypted);
  // }

  static String encryptFile(String path) {
    AesCrypt crypt = AesCrypt();
    crypt.setOverwriteMode(AesCryptOwMode.on);
    crypt.setPassword('my cool password');
    String encFilepath;
    try {
      encFilepath = crypt.encryptFileSync(path);
      print('The encryption has been completed successfully.');
      print('Encrypted file: $encFilepath');
    } catch (e) {
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The encryption has been completed unsuccessfully.');
        print(e.message);
      } else {
        return 'ERROR';
      }
    }
    return encFilepath;
  }

  static String decryptFile(String path) {
    AesCrypt crypt = AesCrypt();
    crypt.setOverwriteMode(AesCryptOwMode.on);
    crypt.setPassword('my cool password');
    String decFilepath;
    try {
      decFilepath = crypt.decryptFileSync(path);
      print('The decryption has been completed successfully.');
      print('Decrypted file 1: $decFilepath');
      print('File content: ' + File(decFilepath).path);
    } catch (e) {
      print(path);
      //AppUtil.showToast('The decryption failed.');
      return 'ERROR';
    }
    return decFilepath;
  }
}

import 'dart:async';

import 'package:Alhany/app_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

Future<User> getCurrentUser() async {
  User currentUser = await Auth().getCurrentUser();
  return currentUser;
}

abstract class BaseAuth {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signInWithCredential(AuthCredential authCredential);

  Future<String> signIn(String email, String password);

  Future<String> signUp(String username, String email, String password);

  // Future<String> currentUser();

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<void> changeEmail(String email);

  Future<String> changePassword(String password);

  Future<void> deleteUser();

  Future<void> sendPasswordResetMail(String email);
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final User user = (await _firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password))
          .user;
      return user;
    } catch (error) {
      if ((error as PlatformException).code ==
          'ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL') {
        AppUtil.showToast(language(
            en: 'This email is used with another login method',
            ar: 'هذا البريد مستخدم بطريقة دخول أخرى'));
      }
    }
    return null;
  }

  Future<User> signInWithCredential(AuthCredential authCredential) async {
    try {
      final User user =
          (await _firebaseAuth.signInWithCredential(authCredential)).user;
      return user;
    } catch (error) {
      if ((error as PlatformException).code ==
          'ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL') {
        AppUtil.showToast(language(
            en: 'This email is used with another login method',
            ar: 'هذا البريد مستخدم بطريقة دخول أخرى'));
      }
    }
    return null;
  }

  @override
  Future<String> signIn(String email, String password) async {
    User user = (await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user.emailVerified) return user.uid;
    return null;
  }

  // ignore: missing_return
  Future<String> signUp(String username, String email, String password) async {
    User user;
    try {
      user = (await _firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user;
    } catch (signUpError) {
      if (signUpError is PlatformException) {
        print('Sign up error: ${signUpError.code}');
        if (signUpError.code == 'ERROR_EMAIL_ALREADY_IN_USE') {
          return 'Email is already in use';
        } else if (signUpError.code == 'ERROR_WEAK_PASSWORD') {
          return 'Weak Password';
        } else if (signUpError.code == 'ERROR_INVALID_EMAIL') {
          return 'Invalid Email';
        } else {
          return 'sign_up_error';
        }
      }
    }

    try {
      await user.sendEmailVerification();
      return user.uid;
    } catch (e) {
      print("An error occurred while trying to send verification email");
      print(e.message);
    }
  }

  // @override
  // Future<String> currentUser() async {
  //   final FirebaseUser user = await _firebaseAuth.currentUser();
  //   return user?.uid;
  // }

  Future<User> getCurrentUser() async {
    User user = await _firebaseAuth.currentUser;
    return user;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    User user = await _firebaseAuth.currentUser;
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    User user = await _firebaseAuth.currentUser;
    return user.emailVerified;
  }

  @override
  Future<void> changeEmail(String email) async {
    User user = await _firebaseAuth.currentUser;
    user.updateEmail(email).then((_) {
      print("Successfully changed email");
    }).catchError((error) {
      print("email can't be changed" + error.toString());
    });
    return null;
  }

  @override
  Future<String> changePassword(String password) async {
    try {
      User user = await _firebaseAuth.currentUser;
      await user.updatePassword(password);
      print("Successfully changed password");
      return null;
    } catch (error) {
      print("Password can't be changed " + error.code);
      return error.code;
    }
  }

  @override
  Future<void> deleteUser() async {
    User user = await _firebaseAuth.currentUser;
    user.delete().then((_) {
      print("Succesfull user deleted");
    }).catchError((error) {
      print("user can't be delete" + error.toString());
    });
    return null;
  }

  @override
  Future<void> sendPasswordResetMail(String email) async {
    print('===========>' + email);
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    return null;
  }
}

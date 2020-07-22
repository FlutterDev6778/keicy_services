import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class _BaseAuth {
  Future<Map<String, dynamic>> signIn({@required String email, @required String password});

  Future<Map<String, dynamic>> signUp({@required String email, @required String password});

  Future<FirebaseUser> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class KeicyAuthentication implements _BaseAuth {
  static KeicyAuthentication _instance = KeicyAuthentication();
  static KeicyAuthentication get instance => _instance;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    signInOption: SignInOption.standard,
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  Future<Map<String, dynamic>> signIn({@required String email, @required String password}) async {
    try {
      FirebaseUser user = (await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password)).user;
      return {"state": "success", "user": user};
    } catch (e) {
      List<String> list = e.toString().split(RegExp(r'(PlatformException\()|(FirebaseError)|([(:,.)])'));

      String errorString = list[2];
      String errorCode;
      if (e.toString().contains("PlatformException")) {
        errorCode = list[1];
      } else if (e.toString().contains("FirebaseError")) {
        errorCode = list[4];
      } else {
        errorCode = list[2];
      }

      ///   --- Error Codes ---
      /// ERROR_USER_NOT_FOUND, ERROR_WRONG_PASSWORD,ERROR_NETWORK_REQUEST_FAILED
      ///
      return {"state": "fail", "errorCode": errorCode, "errorString": errorString};
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      FirebaseUser user = await _firebaseAuth.currentUser();
      if (user.isEmailVerified == false) user.sendEmailVerification();
    } catch (e) {}
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

  Future<Map<String, dynamic>> signUp({@required String email, @required String password}) async {
    try {
      FirebaseUser user = (await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password)).user;
      return {"state": "success", "user": user};
    } catch (e) {
      List<String> list = e.toString().split(RegExp(r'(PlatformException\()|(FirebaseError)|([(:,.)])'));

      String errorString = list[2];
      String errorCode;
      if (e.toString().contains("PlatformException")) {
        errorCode = list[1];
      } else if (e.toString().contains("FirebaseError")) {
        errorCode = list[4];
      } else {
        errorCode = list[2];
      }

      ///   --- Error Codes ---
      /// ERROR_EMAIL_ALREADY_IN_USE, ERROR_NETWORK_REQUEST_FAILED,
      ///
      return {"state": "fail", "errorCode": errorCode, "errorString": errorString};
    }
  }

  Future<FirebaseUser> getCurrentUser() async {
    try {
      FirebaseUser user = await _firebaseAuth.currentUser();
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<FirebaseUser> anonySignIn() async {
    return (await _firebaseAuth.signInAnonymously()).user;
  }

  Future<FirebaseUser> googleSignIn() async {
    try {
      final GoogleSignInAccount _googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication _googleAuth = await _googleUser.authentication;
      final AuthCredential _credential = GoogleAuthProvider.getCredential(
        accessToken: _googleAuth.accessToken,
        idToken: _googleAuth.idToken,
      );
      FirebaseUser user = (await _firebaseAuth.signInWithCredential(_credential)).user;
      return user;
    } catch (e) {
      return null;
    }
  }
}

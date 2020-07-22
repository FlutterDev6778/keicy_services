import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class KeicyStorageForMobile {
  static KeicyStorageForMobile _instance = KeicyStorageForMobile();
  static KeicyStorageForMobile get instance => _instance;

  Future<String> uploadFileObject({@required String path, @required String fileName, @required File file}) async {
    try {
      fileName = _getValidatedFileName(fileName);
      StorageReference storageReference = FirebaseStorage.instance.ref().child("$path$fileName");
      StorageUploadTask uploadTask = storageReference.putFile(file);
      final StreamSubscription<StorageTaskEvent> streamSubscription = uploadTask.events.listen((event) {});
      await uploadTask.onComplete;
      streamSubscription.cancel();
      return await storageReference.getDownloadURL();
    } catch (e) {
      return "unknown";
    }
  }

  Future<String> uploadByteData({@required String path, @required String fileName, @required Uint8List byteData}) async {
    try {
      fileName = _getValidatedFileName(fileName);
      StorageReference storageReference = FirebaseStorage.instance.ref().child("$path$fileName");
      StorageUploadTask uploadTask = storageReference.putData(byteData);
      final StreamSubscription<StorageTaskEvent> streamSubscription = uploadTask.events.listen((event) {});
      await uploadTask.onComplete;
      streamSubscription.cancel();
      uploadTask.cancel();
      return await storageReference.getDownloadURL();
    } catch (e) {
      return "unknown";
    }
  }

  String _getValidatedFileName(String fileName) {
    var listFileName = fileName.split('.');
    String extention = listFileName[listFileName.length - 1];
    String fName = fileName.substring(0, fileName.length - extention.length - 2);
    return "${fName}_${Random().nextInt(10000000).toString()}.$extention";
  }
}

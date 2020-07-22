import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class KeicyFCMForMobile {
  static KeicyFCMForMobile _instance = KeicyFCMForMobile();
  static KeicyFCMForMobile get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  BuildContext _context;
  String _serverToken;

  static Future<dynamic> _myBackgroundMessageHandler(Map<String, dynamic> message) async {
    if (message.containsKey('data')) {
      final dynamic data = message['data'];
    } else if (message.containsKey('notification')) {
      final dynamic notification = message['notification'];
    } else {}
  }

  Future<void> init({@required BuildContext context, @required String serverToken}) async {
    _context = context;
    _serverToken = serverToken;
    if (Platform.isIOS) {
      _firebaseMessaging.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
      _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
        print("Settings registered: $settings");
      });
    }
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _showItemDialog(message);
      },
      onBackgroundMessage: Platform.isIOS ? null : _myBackgroundMessageHandler,
      onResume: (Map<String, dynamic> message) async {
        print("onResume");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch");
      },
    );
  }

  Future<String> getToken() async {
    try {
      var token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      return "-1";
    }
  }

  Future<Map<String, dynamic>> sendMessage(String body, String title, String partnerToken) async {
    var result = await _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true),
    );

    Response response = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{'body': body, 'title': title},
          'priority': 'high',
          'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'id': '1', 'status': 'done'},
          'to': partnerToken,
        },
      ),
    );
    return json.decode(response.body);
  }

  void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: _context,
      builder: (_) => _buildDialog(_context, message),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        // _navigateToItemDetail(message);
      }
    }).catchError((e) {
      print(e);
    });
  }

  // void _navigateToItemDetail(Map<String, dynamic> message) {
  //   final Item item = _itemForMessage(message);
  //   // Clear away dialogs
  //   Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
  //   if (!item.route.isCurrent) {
  //     Navigator.push(context, item.route);
  //   }
  // }
}

Widget _buildDialog(BuildContext context, Map<String, dynamic> message) {
  try {
    return AlertDialog(
      content: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: Colors.black, height: 2),
          children: <TextSpan>[
            TextSpan(text: message["notification"]["title"], style: TextStyle(color: Colors.black, fontSize: 20)),
            TextSpan(text: "\n", style: TextStyle(color: Colors.black, fontSize: 20)),
            TextSpan(text: message["notification"]["body"], style: TextStyle(color: Colors.black, fontSize: 16))
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ],
    );
  } catch (e) {
    print(e);
    return SizedBox();
  }
}

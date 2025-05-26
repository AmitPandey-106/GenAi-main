import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeNotifications();
  }

  void _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Notification permission granted.");
    } else {
      print("Notification permission denied.");
    }
  }


  void _initializeNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("Device Token: $token"); // Save this token in Firebase DB or share it with another device
  }

  Future<void> _sendNotification() async {
    String serverKey = "YOUR_SERVER_KEY"; // Get from Firebase Console
    String targetToken = "TARGET_DEVICE_FCM_TOKEN"; // Replace with receiver's token

    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    var body = jsonEncode({
      "to": targetToken,
      "notification": {
        "title": "Password Change Request",
        "body": "Your password change request has been sent to the Cluster Head.",
        "sound": "default"
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      },
    });

    try {
      var response = await http.post(url, headers: headers, body: body);
      print("FCM Response: ${response.body}");
    } catch (e) {
      print("Error sending FCM notification: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Do you really want to change your password? A change password notification will be sent to the Cluster Head.",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Send Notification",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

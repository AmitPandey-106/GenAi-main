import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genai/user_pages/signin.dart';
import 'package:genai/head_nav.dart'; // Admin page
import 'package:genai/user_nav.dart'; // User page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String? role;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _checkUserRole();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  Future<void> _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role');

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        if (role == null || role!.isEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SignInPage()),
          );
        } else if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HeadNav()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => UserNav()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.orange.withOpacity(0.4),
                BlendMode.srcOver,
              ),
              child: Image.asset(
                'assets/images/mdm.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                ClipPath(
                  clipper: GreenCurveClipper(),
                  child: Container(
                    width: screenWidth,
                    height: screenHeight * 0.5,
                    color: Colors.green.shade500,
                  ),
                ),
                ClipPath(
                  clipper: WhiteCurveClipper(),
                  child: Container(
                    width: screenWidth,
                    height: screenHeight * 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                    height: 190,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WhiteCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.55, size.height * 0.65, size.width, size.height * 0);
    path.quadraticBezierTo(
        size.width * 0.65, size.height * 0.85, 0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class GreenCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.65, size.height * 0.85, size.width, size.height * 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions (important for iOS)
  await messaging.requestPermission();

  // Get the FCM device token (optional: send to server)
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Store token in Firebase Realtime Database
  if (token != null) {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final tokensRef = database.child('GenAi/admin_tokens');

      // Get existing tokens to check for duplicates and determine next token number
      final DataSnapshot snapshot = await tokensRef.get();
      int tokenCount = 0;
      bool tokenExists = false;

      if (snapshot.exists && snapshot.value is Map) {
        Map<dynamic, dynamic> tokensMap = snapshot.value as Map;
        tokenCount = tokensMap.length;

        // Check if token already exists
        tokenExists = tokensMap.values.contains(token);
      }

      // Only add token if it doesn't already exist
      if (!tokenExists) {
        // Add token with sequential numbering
        final tokenRef = tokensRef.child('token${tokenCount + 1}');
        await tokenRef.set(token);
        print('Token stored successfully in Firebase database!');
      } else {
        print('Token already exists in database, not adding duplicate.');
      }
    } catch (e) {
      print('Error storing token in Firebase: $e');
    }
  }

  // Foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      var flutterLocalNotificationsPlugin;
      flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'message_channel',
            'Admin Messages',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}
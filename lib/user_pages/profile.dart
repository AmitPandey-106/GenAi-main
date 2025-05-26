import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:genai/cluster_head/wellness_uploads.dart';
import 'package:genai/user_pages/scheduling_inspection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genai/user_pages/signin.dart';
import '../cluster_head/sanitization_uploads.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String phone = "";
  String email = "";
  String role = "";
  String? udise;

  final DatabaseReference _database = FirebaseDatabase.instance.ref("GenAi").child("members");

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    udise = prefs.getString('udise'); // Retrieve stored UDISE
    if (udise == null) return;

    final snapshot = await _database.child(udise!).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      print("userdata: $data");

      setState(() {
        name = data["college"] ?? "N/A";
        phone = data["phone"] ?? "N/A";
        email = data["email"] ?? "N/A";
        role = data["role"] ?? "N/A";
      });
    }
  }

  Future<void> _signout() async {
    bool confirmSignOut = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sign Out"),
          content: Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Confirm
              child: Text("Yes"),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed

    if (confirmSignOut) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(color: Colors.white, fontSize: 20),),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/profileimage.png"),
            ),
            SizedBox(height: 10),
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(role, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Profile"),
              onTap: () async {
                final updatedData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      name: name,
                      phone: phone,
                      email: email,
                    ),
                  ),
                );
                if (updatedData != null) {
                  setState(() {
                    name = updatedData['name'];
                    phone = updatedData['phone'];
                    email = updatedData['email'];
                  });
                }
              },
            ),
            if (role == "user")
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("Sanitation History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SanitizationUploads(),
                  ),
                );
              },
            ),
            if (role == "user")
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("Student Wellness History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WellnessUploads(),
                  ),
                );
              },
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _signout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // A strong sign-out color
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // Better padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                ),
                elevation: 5, // Gives a slight shadow for depth
              ),
              child: Text(
                "Sign Out",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

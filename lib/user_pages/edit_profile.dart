import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';


class EditProfilePage extends StatefulWidget {
  final String name;
  final String phone;
  final String email;

  EditProfilePage({
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  bool _isLoading = false;
  String? udise;

  final DatabaseReference _database = FirebaseDatabase.instance.ref("GenAi").child("members");

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phone);
    emailController = TextEditingController(text: widget.email);
    _getUserUDISE(); // Load UDISE from SharedPreferences
  }

  Future<void> _getUserUDISE() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      udise = prefs.getString('udise');
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (udise == null) return;

    setState(() => _isLoading = true);

    try {
      await _database.child(udise!).update({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );

      Navigator.pop(context, {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile. Please try again.")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            SizedBox(height: 20),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
            SizedBox(height: 20),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // More vibrant color
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // More padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                elevation: 5, // Shadow effect
              ),
              child: _isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                "Save",
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

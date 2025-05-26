import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:genai/head_nav.dart';
import 'package:genai/user_nav.dart';
import 'change_password.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref("GenAi").child("members");

  @override
  void initState() {
    super.initState();
    _idController.addListener(_validateInput);
    _passwordController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      _isButtonEnabled = _idController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    });
  }

  void _signIn() async {
    setState(() => _isLoading = true);

    final udise = _idController.text.trim();
    final password = _passwordController.text.trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        // Fetch user details from Firebase
        final snapshot = await _database.child(udise).get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final collegeName = data["college"];
          final storedPassword = data["password"];
          final role = data["role"] ?? "user";

          if (storedPassword == password) {
            await prefs.setString('role', role);
            await prefs.setString('collegeName', collegeName);
            await prefs.setString('udise', udise);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>
              role == "admin"
                  ? HeadNav()
                  : UserNav()),
            );
          } else {
            _showErrorDialog("Incorrect password");
          }
        } else {
          _showErrorDialog("User not found");
        }
      } catch (e) {
        _showErrorDialog("Error signing in. Please try again.");
      }

    setState(() => _isLoading = false);

  }

// Function to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/food_safety.jpg", fit: BoxFit.cover),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                color: Color(0xFFE3F2FD),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 40),
                    Text("Welcome", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                    SizedBox(height: 40),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: "ID Number",
                        prefixIcon: Icon(Icons.perm_identity),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 40),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                            );
                          },
                          child: Text("Forgot password?", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled ? _signIn : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonEnabled ? Colors.blue : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Sign in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

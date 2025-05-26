import 'package:flutter/material.dart';
import 'package:genai/user_pages/food_inspection.dart';
import 'package:genai/user_pages/profile.dart';
import 'package:genai/user_pages/sanitation_inspection.dart';
import 'package:genai/user_pages/scheduling_inspection.dart';

import 'home_page.dart';

class UserNav extends StatefulWidget {
  @override
  _UserNavState createState() => _UserNavState();
}

class _UserNavState extends State<UserNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    // FoodInspect(),
    // SanitationInspect(),
    SchedulingInspect(),
    ProfilePage(),
  ];

  // List of titles for AppBar
  // final List<String> _titles = [
  //   "Home",
  //   "Food Inspection",             // Title for YearPage
  //   "Sanitation Inspection", // Title for UploadAssignmentPage
  //   // "Inspection History",
  //   "Profile",           // Title for ProfilePage
  // ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_titles[_selectedIndex], style: TextStyle(color: Colors.white),), // Dynamically change title
      //   backgroundColor: Colors.lightBlue,
      // ),
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Food'),
          // BottomNavigationBarItem(icon: Icon(Icons.sanitizer), label: 'Sanitation'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:genai/cluster_head/wellness_uploads.dart';
import 'package:genai/user_pages/profile.dart';
import 'cluster_head/add_member.dart';
import 'cluster_head/food_uploads.dart';
import 'cluster_head/sanitization_uploads.dart';


class HeadNav extends StatefulWidget {
  @override
  _HeadNavState createState() => _HeadNavState();
}

class _HeadNavState extends State<HeadNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    FoodUploads(),
    SanitizationUploads(),
    WellnessUploads(),
    AddMemberPage(),
    ProfilePage(),
  ];

  // List of titles for AppBar
  // final List<String> _titles = [
  //   "Food Uploads",             // Title for YearPage
  //   "Sanitation Uploads", // Title for UploadAssignmentPage
  //   "All Members",
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
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.sanitizer), label: 'Sanitation'),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Wellness'),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: 'All Members'),
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

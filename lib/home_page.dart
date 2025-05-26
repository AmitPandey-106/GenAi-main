import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:genai/user_pages/food_inspection.dart';
import 'package:genai/user_pages/sanitation_inspection.dart';
import 'package:genai/user_pages/student_wellness.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Set Location";
  String _fullAddress = ""; // 👈 full address for dialog

  // Tap to show full address in a dialog
  void _showFullAddressDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Location Dialog",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Your Location",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    _fullAddress,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "CLOSE",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }


  //Setting Current Location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _location = "Location Permission Denied";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String building = place.name ?? "";
        String street = place.thoroughfare ?? "";
        String area = place.subLocality ?? "";
        String city = place.locality ?? "";

        // ❗ Ignore Plus Code if it's present in `name`
        if (building.contains(RegExp(r'^[23456789CFGHJMPQRVWX]{4}\+'))) {
          building = '';
        }

        String composed = "";

        if (building.isNotEmpty) composed += "$building, ";
        if (street.isNotEmpty && street != building) composed += "$street, ";
        if (area.isNotEmpty) composed += "$area, ";
        if (city.isNotEmpty) composed += city;

        composed = composed.trim();

        // Remove trailing comma
        if (composed.endsWith(",")) {
          composed = composed.substring(0, composed.length - 1);
        }

        // Truncate if too long
        setState(() {
          _fullAddress = composed;
          _location = composed.length > 35
              ? "${composed.substring(0, 35)}..."
              : composed;
        });
      } else {
        setState(() {
          _location = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        _location = "Error: ${e.toString()}";
      });
    }
  }





  // Carousel Images & Text Data
  final List<Map<String, String>> _carouselItems = [
    {
      "image": "assets/images/main.jpg",
      "title": "Better Schools, Healthier Futures",
      "subtitle": "Daily inspections for food quality and clean facilities.",
    },
    {
      "image": "assets/images/food_ins.jpeg",
      "title": "Food Inspection",
      "subtitle": "Ensuring safe and hygienic meals",
    },
    {
      "image": "assets/images/sanitation_ins.jpg",
      "title": "Sanitation Inspection",
      "subtitle": "Promoting clean and safe environments",
    },
  ];

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: Offset(2, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightTile(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlue,
          title: GestureDetector(
            onTap: _showFullAddressDialog,
            child: Text(
              _location,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.location_on),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carousel
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                  ),
                  items: _carouselItems.map((item) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(item["image"]!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.4),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 40,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"]!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  item["subtitle"]!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 30),

                // App Purpose
                Text(
                  "Welcome to Food & Sanitation Inspection Portal",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ensure the safety and cleanliness of your food environment with digital inspections and real-time reporting.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),

                SizedBox(height: 30),

                // Feature Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureCard(
                      title: "Food Inspection",
                      icon: Icons.fastfood,
                      color: Colors.orange.shade100,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FoodInspect()));
                      },
                    ),
                    _buildFeatureCard(
                      title: "Sanitation",
                      icon: Icons.clean_hands,
                      color: Colors.green.shade100,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SanitationInspect()));
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureCard(
                      title: "Wellness Checkup",
                      icon: Icons.health_and_safety,
                      color: Colors.purple.shade100,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => StudentWellnessPage()));
                      },
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Highlights Grid
                Text(
                  "System Highlights",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildHighlightTile("Digital Reports", Icons.assignment_turned_in),
                    _buildHighlightTile("Live Monitoring", Icons.track_changes),
                    _buildHighlightTile("User Friendly", Icons.mobile_friendly),
                    _buildHighlightTile("Secure & Reliable", Icons.security),
                  ],
                ),

                SizedBox(height: 30),

                // How it works section
                Text(
                  "How it Works",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.camera_alt, color: Colors.blue),
                      title: Text("Capture Food & Sanitation Images"),
                      subtitle: Text("Teachers click photos of food and sanitation for automated analysis."),
                    ),
                    ListTile(
                      leading: Icon(Icons.analytics, color: Colors.orange),
                      title: Text("AI Analysis & Quality Check"),
                      subtitle: Text("Images are analyzed to assess cleanliness and identify food items."),
                    ),
                    ListTile(
                      leading: Icon(Icons.health_and_safety, color: Colors.purple),
                      title: Text("Student Wellness Checkup"),
                      subtitle: Text("Monitor student stress, emotion, BMI using health photos and vital data."),
                    ),
                    ListTile(
                      leading: Icon(Icons.send, color: Colors.green),
                      title: Text("Daily Report Sent to Cluster Head"),
                      subtitle: Text("Compiled reports include school info, images, and teacher credentials."),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Contact Section
                Text(
                  "Need Help or Support?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.contact_support, size: 40, color: Colors.blueAccent),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cluster Head Contact", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Get in touch for reporting or urgent issues.", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )



    );
  }
}

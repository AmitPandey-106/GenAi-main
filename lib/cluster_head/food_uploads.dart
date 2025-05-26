import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:genai/cluster_head/report_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodUploads extends StatefulWidget {
  @override
  _FoodUploadsState createState() => _FoodUploadsState();
}

class _FoodUploadsState extends State<FoodUploads> {
  String _selectedFilter = 'Daily';
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? udise = prefs.getString('udise');

    if (udise == null) {
      print("No UDISE number found");
      return;
    }

    DatabaseReference dbRef = FirebaseDatabase.instance.ref("GenAi").child("members");

    dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, String>> tempReports = [];

        print("UserData:$data");

        data.forEach((userId, userDetails) {
          if (userDetails.containsKey("food_detections")) {
            Map<dynamic, dynamic> foodDetections = userDetails["food_detections"];

            if (foodDetections != null) {
              foodDetections.forEach((date, foodDetails) {
                if (foodDetails != null) {
                  tempReports.add({
                    // From foodDetections
                    'date': foodDetails['SelectedImageUploadedDate']?.toString() ?? "N/A",
                    'time': foodDetails['SelectedImageUplaodedTime']?.toString() ?? "N/A",
                    'udise': foodDetails['udise']?.toString() ?? "N/A",
                    'imageUploadedTime': foodDetails['ImageUplaodedTime']?.toString() ?? "N/A",
                    'imageUploadedDate': foodDetails['ImageUploadedDate']?.toString() ?? "N/A",
                    'annotated_image_url': foodDetails['annotated_image_url']?.toString() ?? "N/A",
                    'total_carbs': foodDetails['total']?['carbs']?.toString() ?? "N/A",
                    'total_protein': foodDetails['total']?['protein']?.toString() ?? "N/A",
                    'total_fat': foodDetails['total']?['fat']?.toString() ?? "N/A",
                    'total_calories': foodDetails['total']?['calories']?.toString() ?? "N/A",
                    'food_quality': foodDetails['food_quality']?.toString() ?? "N/A",
                    'nutritional_summary': foodDetails['nutritional_summary'] != null
                        ? foodDetails['nutritional_summary'].toString()
                        : "N/A",

                    // From userDetails
                    'school': userDetails['college']?.toString() ?? "N/A",
                    'role': userDetails['role']?.toString() ?? "N/A",
                    'password': userDetails['password']?.toString() ?? "N/A",
                  });
                }
              });
            }
          }
        });

        setState(() {
          _reports = tempReports;
          print("UserData2:$_reports");
          _isLoading = false;
        });
      }
    });

  }

  List<Map<String, String>> get _filteredReports {
    String query = _searchController.text.toLowerCase();
    return _reports.where((report) {
      // Safely check if 'udise' and 'school' are not null
      String udise = report['udise'] ?? '';
      String school = report['school'] ?? '';
      return udise.contains(query) || school.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Food Uploads",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Dropdown Filter
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                items: ['Daily', 'Weekly', 'Monthly'].map((String category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Select Report Type'),
              ),
              SizedBox(height: 10),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by UDISE Number or School Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12.0,
                  border: TableBorder.all(color: Colors.grey),
                  columns: [
                    DataColumn(label: Center(child: Text('Date'))),
                    DataColumn(label: Center(child: Text('Time'))),
                    DataColumn(label: Center(child: Text('UDISE Number'))),
                    DataColumn(label: Center(child: Text('School Name'))),
                    DataColumn(label: Center(child: Text('Report'))),
                  ],
                  rows: _filteredReports.map((report) {
                    return DataRow(cells: [
                      DataCell(Center(child: Text(report['date']!))),
                      DataCell(Center(child: Text(report['time']!))),
                      DataCell(Center(child: Text(report['udise']!))),
                      DataCell(Center(child: Text(report['school']!))),
                      DataCell(
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              _viewReport(report);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text('View', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewReport(Map<String, String> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          reportData: {
            ...report,
            // Ensure it's passed as a List
          },
        ),
      ),
    );
  }
}

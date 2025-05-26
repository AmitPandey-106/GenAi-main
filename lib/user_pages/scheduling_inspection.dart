import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cluster_head/report_details_screen.dart';

class SchedulingInspect extends StatefulWidget {
  @override
  _SchedulingInspectState createState() => _SchedulingInspectState();
}

class _SchedulingInspectState extends State<SchedulingInspect> {
  List<Map<String, String>> _scheduleData = [];
  List<Map<String, String>> _filteredData = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserReports();
    _searchController.addListener(_filterReports);
  }

  Future<void> _fetchUserReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('udise');
    String? role = prefs.getString('role');// Get user ID

    if (userId == null) {
      print("No User ID found");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    DatabaseReference dbRef = FirebaseDatabase.instance
        .ref("GenAi")
        .child("members")
        .child(userId)
        .child("food_detections");

    dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, String>> tempReports = [];

        data.forEach((dateKey, detectionDetails) {

          List<dynamic> foodItemsList = detectionDetails['food_items'] ?? [];
          String foodItemsString = foodItemsList.isNotEmpty
              ? foodItemsList.join(', ')
              : 'No Items';

          print("dateKey: $dateKey, detectionDetails: $detectionDetails");

          tempReports.add({
            'role': role?.toString() ?? "user",
            'date': detectionDetails['SelectedImageUploadedDate']?.toString() ?? "N/A",
            'time': detectionDetails['SelectedImageUplaodedTime']?.toString() ?? "N/A",
            'udise': detectionDetails['udise']?.toString() ?? "N/A",
            'imageUploadedTime': detectionDetails['ImageUplaodedTime']?.toString() ?? "N/A",
            'imageUploadedDate': detectionDetails['ImageUploadedDate']?.toString() ?? "N/A",
            'annotated_image_url': detectionDetails['annotated_image_url']?.toString() ?? "N/A",
            'total_carbs': detectionDetails['total']?['carbs']?.toString() ?? "N/A",
            'total_protein': detectionDetails['total']?['protein']?.toString() ?? "N/A",
            'total_fat': detectionDetails['total']?['fat']?.toString() ?? "N/A",
            'total_calories': detectionDetails['total']?['calories']?.toString() ?? "N/A",
            'food_quality': detectionDetails['food_quality']?.toString() ?? "N/A",
            'nutritional_summary': _getNutritionalSummary(detectionDetails['nutritional_summary']),
          });



        });

        if (mounted) {
          setState(() {
            _scheduleData = tempReports;
            _filteredData = tempReports;
            _isLoading = false;
          });
        }
      }
    });
  }

  void _filterReports() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = _scheduleData.where((entry) {
        return entry['date']!.toLowerCase().contains(query) ||
            entry['time']!.toLowerCase().contains(query) ||
            entry['foodItems']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("History", style: TextStyle(color: Colors.white, fontSize: 20),),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Styled Search Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by Date, Time, or Food Items",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Data Table
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey),
                    columns: [
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Report', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _filteredData.map((entry) {
                      return DataRow(cells: [
                        DataCell(Text(entry['date']!)),
                        DataCell(Text(entry['time']!)),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              _viewReport(entry);
                            },
                            child: Text("View"),
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
                      },
        ),
      ),
    );
  }

  String _getNutritionalSummary(Map<dynamic, dynamic>? nutritionalSummary) {
    if (nutritionalSummary == null) return "N/A";

    List<String> summaryList = [];
    nutritionalSummary.forEach((foodItem, details) {
      summaryList.add("$foodItem: ${details['quantity']} ${details['unit']}, "
          "Carbs: ${details['carbs']}, Protein: ${details['protein']}, "
          "Fat: ${details['fat']}, Calories: ${details['calories']}");
    });

    return summaryList.join('; ');
  }

}

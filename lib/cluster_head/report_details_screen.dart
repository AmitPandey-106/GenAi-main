import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  ReportDetailsScreen({required this.reportData});

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // Fetch the role from SharedPreferences
  Future<void> _loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role');  // Fetch the role from SharedPreferences
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the role is still null (i.e., not fetched yet), show a loading indicator
    if (role == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Food Quality Report'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String nutritionalSummary = widget.reportData['nutritional_summary'] ?? "No Nutritional Summary Available";
    print("reportdata: ${widget.reportData}");

    return Scaffold(
      appBar: AppBar(
        title: Text('Food Quality Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Food Detection Report",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // General Report Details
                  _buildReportRow("Date:", widget.reportData['date']?.toString() ?? "***"),
                  _buildReportRow("Time:", widget.reportData['time']?.toString() ?? "**"),
                  _buildReportRow("Image Uploaded Time:", widget.reportData['imageUploadedTime']?.toString() ?? "***"),
                  _buildReportRow("Image Uploaded Date:", widget.reportData['imageUploadedDate']?.toString() ?? "***"),
                  _buildReportRow("UDISE Number:", widget.reportData['udise']?.toString() ?? "***"),
                  _buildReportRow("School:", widget.reportData['school']?.toString() ?? "***"),
                  _buildReportRow("Uploaded Image:", ""),
                  Center(
                    child: widget.reportData['annotated_image_url'] != null && widget.reportData['annotated_image_url'] != ''
                        ? Image.network(widget.reportData['annotated_image_url'])
                        : Text("No image available.", style: TextStyle(fontSize: 16)),
                  ),

                  Divider(), // Adds a visual separation

                  // Check if the role is not 'user' before showing 'Food Quality'
                  if (role != 'user')
                    _buildReportRow("Food Quality:", widget.reportData['food_quality']?.toString() ?? "***"),

                  SizedBox(height: 15),

                  // Nutritional Summary Section
                  Text(
                    "Nutritional Summary:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    nutritionalSummary,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20,),

                  _buildReportRow("Total Carbs:", widget.reportData['total_carbs']?.toString() ?? "***"),
                  _buildReportRow("Total Protein:", widget.reportData['total_protein']?.toString() ?? "***"),
                  _buildReportRow("Total Fat:", widget.reportData['total_fat']?.toString() ?? "***"),
                  _buildReportRow("Total Calories:", widget.reportData['total_calories']?.toString() ?? "***"),

                  SizedBox(height: 20),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Close Report"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 74, vertical: 16),
                        textStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

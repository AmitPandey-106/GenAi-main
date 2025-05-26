import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure you import this!

class SanitizationUploads extends StatefulWidget {
  @override
  _SanitizationUploadsState createState() => _SanitizationUploadsState();
}

class _SanitizationUploadsState extends State<SanitizationUploads> {
  String _selectedFilter = 'Daily';
  TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> _reports = [];
  String? storedUdise;
  String? storedRole;

  List<Map<String, String>> get _filteredReports {
    String query = _searchController.text.toLowerCase();
    // If the role is 'user', filter by the stored UDISE
    if (storedRole == "user") {
      return _reports.where((report) =>
      report['udise'] == storedUdise).toList();
    }
    else{
      // If role is not user or UDISE is not set, just filter by search
      return _reports.where((report) =>
      report['udise']!.contains(query) || report['school']!.toLowerCase().contains(query)).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoredUdise();
    fetchSanitizationReports();
  }

  Future<void> _loadStoredUdise() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? udise = prefs.getString('udise');
    String? role = prefs.getString('role');
    setState(() {
      storedUdise = udise;
      storedRole = role;
    });
  }

  Future<void> fetchSanitizationReports() async {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref("GenAi").child("sanitization_detections");

    dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, String>> tempReports = [];

        print("Data Retrieved: $data");

        data.forEach((key, value) {
          print("Processing Entry Key: $key");

          if (value != null) {
            tempReports.add({
              'udise': value['udise']?.toString() ?? 'No UDISE',
              'date': value['SelectedImageUploadedDate']?.toString() ?? 'No Date',
              'time': value['SelectedImageUploadedTime']?.toString() ?? 'No Time',
              'prediction': value['prediction_result']?.toString() ?? 'No Prediction',
              'predictionUrl': value['predictionResultUrl']?.toString() ?? 'No Prediction Image',
              'report': 'View',
              'school': value['collegeName']?.toString() ?? 'No School Name',  // Still hardcoded
            });
            print("Added report: $value");
          }
        });

        setState(() {
          _reports = tempReports;
          print("Fetched Reports: $_reports");
        });
      } else {
        print("No data found.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sanitation Uploads", style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  border: OutlineInputBorder(),
                  labelText: 'Select Report Type',
                ),
              ),
              SizedBox(height: 10),
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
              SingleChildScrollView(
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
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Sanitization Report'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('UDISE: ${report['udise']}'),
                                        Text('Date: ${report['date']}'),
                                        Text('Time: ${report['time']}'),
                                        Text('Prediction: ${report['prediction']}'),
                                        SizedBox(height: 10),
                                        report['predictionUrl'] != null && report['predictionUrl']!.isNotEmpty
                                            ? Image.network(
                                          report['predictionUrl']!,
                                          height: 200,
                                          width: 200,
                                          fit: BoxFit.cover,
                                        )
                                            : Text('No image available'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
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
}

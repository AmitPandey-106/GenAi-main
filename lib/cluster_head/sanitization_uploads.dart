import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
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

  Future<void> generatePdf(BuildContext context, Map<String, String> report) async {
    final pdf = pw.Document();

    final Map<String, String> readableLabels = {
      'udise': 'UDISE Code',
      'date': 'Upload Date',
      'time': 'Upload Time',
      'prediction': 'Prediction',
      'school': 'College Name',
      'predictionUrl': 'Sanitization Image',
    };

    pw.Widget? imageWidget;
    if (report['predictionUrl'] != null && report['predictionUrl']!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(report['predictionUrl']!));
        if (response.statusCode == 200) {
          final image = pw.MemoryImage(response.bodyBytes);
          imageWidget = pw.Center(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              height: 150,
              width: 150,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover),
              ),
            ),
          );
        }
      } catch (e) {
        print("Image load failed: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Sanitization Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              if (imageWidget != null) imageWidget,
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                },
                children: report.entries.where((entry) => entry.key != 'predictionUrl' && entry.key != 'report').map((entry) {
                  final label = readableLabels[entry.key] ?? entry.key;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${entry.value}'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sanitization_report_${report['udise']}_${report['date']}.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
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
                                      ElevatedButton.icon(
                                        onPressed: () => generatePdf(context, report),
                                        icon: const Icon(Icons.download),
                                        label: const Text('Download Report'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
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

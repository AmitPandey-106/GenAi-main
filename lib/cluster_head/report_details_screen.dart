import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();

    final report = widget.reportData;
    final imageUrl = report['annotated_image_url'];

    pw.Widget? imageWidget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
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
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "Food Quality Report",
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                if (imageWidget != null) imageWidget,

                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(5),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  children: [
                    _buildTableRow("School", report['school']),
                    _buildTableRow("UDISE", report['udise']),
                    _buildTableRow("Date", report['date']),
                    _buildTableRow("Time", report['time']),
                    _buildTableRow("Image Uploaded Date", report['imageUploadedDate']),
                    _buildTableRow("Image Uploaded Time", report['imageUploadedTime']),
                    if (role != 'user') _buildTableRow("Food Quality", report['food_quality']),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Text("Nutritional Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blueGrey),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Text(report['nutritional_summary'] ?? '---', style: pw.TextStyle(fontSize: 14)),
                ),

                pw.SizedBox(height: 20),
                pw.Text("Nutritional Breakdown", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(5),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  children: [
                    _buildTableRow("Total Carbs", report['total_carbs']),
                    _buildTableRow("Total Protein", report['total_protein']),
                    _buildTableRow("Total Fat", report['total_fat']),
                    _buildTableRow("Total Calories", report['total_calories']),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/food_quality_report_${report['udise']}_${report['date']}.pdf');
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path);
  }

  pw.TableRow _buildTableRow(String label, dynamic value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value?.toString() ?? '---'),
        ),
      ],
    );
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
                      onPressed: _downloadPDF,
                      child: Text("Download Report"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 70, vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

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

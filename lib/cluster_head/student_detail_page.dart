import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;

class StudentDetailPage extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentDetailPage({super.key, required this.studentData});

  Future<void> generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    final Map<String, String> readableLabels = {
      'standard': 'Standard',
      'stress': 'Stress Status',
      'ImageUploadedDate': 'Upload Date',
      'stressScore': 'Stress Score',
      'gender': 'Gender',
      'image_url': 'Student Image',
      'confidence': 'Confidence Level',
      'rollNo': 'Roll No',
      'weight': 'Weight',
      'collegeName': 'College Name',
      'emotion': 'Emotion',
      'udise': 'UDISE Code',
      'reportDate': 'Report Date',
      'name': 'Student Name',
      'ImageUploadedTime': 'Upload Date',
      'age': 'Age',
      'height': 'Height',
      'reportTime': 'Report Time',
    };

    // Try to load the image if URL is valid
    pw.Widget? imageWidget;
    if (studentData['image_url'] != null) {
      try {
        final response = await http.get(Uri.parse(studentData['image_url']));
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
              pw.Text("Student Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              if (imageWidget != null) imageWidget,
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                },
                children: studentData.entries.where((entry) => entry.key != 'image_url').map((entry) {
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
    final file = File('${dir.path}/student_report_${studentData['rollNo']}.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> readableLabels = {
      'standard': 'Standard',
      'stress': 'Stress Status',
      'ImageUploadedDate': 'Upload Date',
      'stressScore': 'Stress Score',
      'gender': 'Gender',
      'image_url': 'Student Image',
      'confidence': 'Confidence Level',
      'rollNo': 'Roll No',
      'weight': 'Weight',
      'collegeName': 'College Name',
      'emotion': 'Emotion',
      'udise': 'UDISE Code',
      'reportDate': 'Report Date',
      'name': 'Student Name',
      'ImageUploadedTime': 'Upload Date',
      'age': 'Age',
      'height': 'Height',
      'reportTime': 'Report Time',
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Student Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (studentData['image_url'] != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    studentData['image_url'],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: studentData.entries.where((entry) => entry.key != 'image_url').map((entry) {
                final label = readableLabels[entry.key] ?? entry.key;
                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      color: Colors.grey[200],
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('${entry.value}'),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Download Report"),
              onPressed: () => generatePdf(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WellnessUploads extends StatefulWidget {
  @override
  _WellnessUploadsState createState() => _WellnessUploadsState();
}

class _WellnessUploadsState extends State<WellnessUploads> {
  List<String> collegeList = ['vppcoe', 'ssdv', 'aryahs'];
  List<String> standardList = List.generate(10, (index) => (index + 1).toString());

  String? selectedCollege;
  String? selectedStandard;

  String? userRole;
  String? CollegeName;

  TextEditingController rollController = TextEditingController();

  List<Map<String, dynamic>> studentDataList = [];

  final dbRef = FirebaseDatabase.instance.ref("GenAi").child("student_wellness_detections");


  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role') ?? 'user'; // Default role is 'user'
      CollegeName = prefs.getString('collegeName');
      if (userRole == 'user') {
        selectedCollege = CollegeName; // Set from prefs
      }
    });
  }

  Future<void> fetchStudents(String collegeName, String standard) async {
    final snapshot = await dbRef.child(collegeName).child(standard).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      print("Fetched data: $data");

      List<Map<String, dynamic>> allStudents = [];

      data.forEach((key, value) {
        if (value is Map) {
          final studentMap = Map<String, dynamic>.from(value);
          // If roll number is entered, filter by roll number
          if (rollController.text.isEmpty || studentMap['rollNo'] == rollController.text.trim()) {
            allStudents.add(studentMap);
          }
        }
      });

      setState(() {
        studentDataList = allStudents;
      });
    } else {
      setState(() {
        studentDataList = [];
      });
      print("No data found for $collegeName - $standard");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Retrieve Student Wellness"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // College Dropdown
            if (userRole != 'user') ...[
            DropdownButton<String>(
              value: selectedCollege,
              hint: Text("Select College"),
              isExpanded: true,
              items: collegeList.map((college) {
                return DropdownMenuItem<String>(
                  value: college,
                  child: Text(college),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCollege = value;
                  selectedStandard = null;
                });
              },
            ),
            ],
            SizedBox(height: 16),

            // Standard Dropdown
            DropdownButton<String>(
              value: selectedStandard,
              hint: Text("Select Standard"),
              isExpanded: true,
              items: standardList.map((std) {
                return DropdownMenuItem<String>(
                  value: std,
                  child: Text(std),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStandard = value;
                });
              },
            ),

            SizedBox(height: 12),

            TextField(
              controller: rollController,
              decoration: InputDecoration(
                labelText: "Enter Roll Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 16),

            // Search Button
            ElevatedButton.icon(
              onPressed: (selectedCollege != null && selectedStandard != null)
                  ? () => fetchStudents(selectedCollege!, selectedStandard!)
                  : null,
              icon: Icon(Icons.search),
              label: Text("Search"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),

            // Display Data
            Expanded(
              child: studentDataList.isEmpty
                  ? Center(child: Text("No data found"))
                  : ListView.builder(
                itemCount: studentDataList.length,
                itemBuilder: (context, index) {
                  final student = studentDataList[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: student['image_url'] != null
                          ? Image.network(
                        student['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.person),
                      title: Text("Name: ${student['name']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("College: ${student['collegeName']}, UDISE: ${student['udise']}"),
                          Text("Roll No: ${student['rollNo']}"),
                          Text("Emotion: ${student['emotion']} | Stress: ${student['stress']}"),
                          Text("Age: ${student['age']}, Gender: ${student['gender']}"),
                          Text("Height: ${student['height']}, Weight: ${student['weight']}"),
                          Text("Uploaded: ${student['ImageUploadedDate']} at ${student['ImageUploadedTime']}"),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Confidence: ${student['confidence']}"),
                          Text("Stress Score: ${student['stressScore']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )

          ],
        ),
      ),
    );
  }
}

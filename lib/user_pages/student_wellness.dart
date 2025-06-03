import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentWellnessPage extends StatefulWidget {
  @override
  _StudentWellnessPageState createState() => _StudentWellnessPageState();
}

class _StudentWellnessPageState extends State<StudentWellnessPage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedDate = "Select Date";
  String _selectedTime = "Select Time";
  File? _image;
  bool _isSubmitEnabled = false;
  String? _fileName;
  double? _bmi;
  String _bmiResult = "";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stdController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked.format(context);
      });
    }
  }

  Future<void> _pickImage() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select Date and Time first!")),
      );
      return;
    }

    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Choose Image"),
        actions: [
          TextButton(
            child: Text("Camera"),
            onPressed: () async {
              Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera));
            },
          ),
          TextButton(
            child: Text("Gallery"),
            onPressed: () async {
              Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
            },
          ),
        ],
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _fileName = pickedFile.name;
        _isSubmitEnabled = true;
      });
    }
  }

  bool _isFormComplete() {
    if (_selectedDate == 'Select Date') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date')),
      );
      return false;
    }
    if (_selectedTime == 'Select Time') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Time')),
      );
      return false;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Photo')),
      );
      return false;
    }
    return true;
  }


  void _calculateBMI() {
    double? height = double.tryParse(_heightController.text);
    double? weight = double.tryParse(_weightController.text);
    if (height != null && weight != null && height > 0) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      String result = "";
      if (bmi < 18.5)
        result = "Underweight";
      else if (bmi < 24.9)
        result = "Normal";
      else if (bmi < 29.9)
        result = "Overweight";
      else
        result = "Obese";

      setState(() {
        _bmi = bmi;
        _bmiResult = result;
      });
    }
  }

  Future<void> _submitImage() async {

    if (_nameController.text.isEmpty ||
        _rollNoController.text.isEmpty ||
        _stdController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _genderController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All fields and image are required")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://web-production-4f74.up.railway.app/api/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', _image!.path),
    );

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("Server responded with status: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseBody);

        if (jsonData.containsKey('emotion') && jsonData.containsKey('stress')) {
          String emotion = jsonData['emotion'];
          String stress = jsonData['stress'];
          String stressScore = jsonData['stress_score'];
          String confidence = jsonData['confidence'];
          String imageUrl = jsonData['image_url'];

          // Get UDISE and college name from shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var udise = prefs.getString('udise');
          var collegeName = prefs.getString('collegeName');

          DateTime now = DateTime.now();
          String formattedDate = "${now.year}-${now.month}-${now.day}";
          String formattedTime = "${now.hour}:${now.minute}";

          // Save to Firebase
          DatabaseReference dbRef = FirebaseDatabase.instance
              .ref("GenAi")
              .child("student_wellness_detections");

          DatabaseReference newRef = dbRef.child(collegeName!).child(_stdController.text).push();

          await newRef.set({
            "udise": udise,
            "collegeName": collegeName,
            "reportDate": formattedDate,
            "reportTime": formattedTime,
            "rollNo": _rollNoController.text,
            "name": _nameController.text,
            "standard": _stdController.text,
            "age": _ageController.text,
            "gender": _genderController.text,
            "height": _heightController.text,
            "weight": _weightController.text,
            "emotion": emotion,
            "stress": stress,
            "confidence": confidence,
            "stressScore": stressScore,
            "image_url": imageUrl,
            "ImageUploadedDate": formattedDate,
            "ImageUploadedTime": formattedTime,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Student wellness data saved successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid response from API")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Student Wellness Check",style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.lightBlue,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Student Health Checkup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                SizedBox(height: 4),
                Text("Upload a student’s photo and required details to analyze emotional state, predict stress levels, and calculate BMI.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 20),

                // Section Title: Date & Time
                Row(
                  children: [
                    Icon(Icons.event, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text("Select Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.date_range, size: 18),
                        label: Text(_selectedDate, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11)),
                        onPressed: _selectDate,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.access_time),
                        label: Text(_selectedTime, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11)),
                        onPressed: _selectTime,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Section Title: Upload Photo
                Row(
                  children: [
                    Icon(Icons.image, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text("Upload Image for Health Check", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.lightBlueAccent),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade100,
                      image: _image != null
                          ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _image == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blueAccent, size: 40),
                          SizedBox(height: 10),
                          Text("Tap to upload image", style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: 20),

                // File Info and Analysis
                if (_image != null) ...[
                  Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName ?? "Image Selected",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Analysis Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),

                  // Row(
                  //   children: [
                  //     Icon(Icons.fastfood, color: Colors.deepPurple),
                  //     SizedBox(width: 8),
                  //     Text("Food Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                  //     SizedBox(width: 6),
                  //     Text(_detectedFood ?? "Detecting..."),
                  //   ],
                  // ),
                  // SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Icon(Icons.health_and_safety, color: Colors.green),
                  //     SizedBox(width: 8),
                  //     Text("Quality:", style: TextStyle(fontWeight: FontWeight.bold)),
                  //     SizedBox(width: 6),
                  //     Text(_isFoodGood ? "Good" : "Bad", style: TextStyle(color: _isFoodGood ? Colors.green : Colors.red)),
                  //   ],
                  // ),
                  // SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Icon(Icons.local_fire_department, color: Colors.orange),
                  //     SizedBox(width: 8),
                  //     Text("Calories:", style: TextStyle(fontWeight: FontWeight.bold)),
                  //     SizedBox(width: 6),
                  //     Text(_calories ?? "Calculating..."),
                  //   ],
                  // ),
                ],

                SizedBox(height: 20),

                // Section Title: Student Details
                Row(
                  children: [
                    Icon(Icons.assignment_ind, color: Colors.teal),
                    SizedBox(width: 8),
                    Text("Enter Student Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // 👈 Make label column a bit narrower
                        1: FlexColumnWidth(1.8), // 👈 Give more room to the text field
                      },
                      children: [
                        _buildTableRow("Roll No", _rollNoController, Icons.person),
                        _buildTableRow("Name", _nameController, Icons.person),
                        _buildTableRow("Standard", _stdController, Icons.class_),
                        _buildTableRow("Age", _ageController, Icons.cake),
                        _buildTableRow("Gender", _genderController, Icons.wc),
                        _buildTableRow("Height", _heightController, Icons.height),
                        _buildTableRow("Weight", _weightController, Icons.monitor_weight),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Section Title: BMI
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calculate),
                    label: Text("Calculate BMI", style: TextStyle(color: Colors.white)),
                    onPressed: _calculateBMI,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(80, 40), // Square shape
                      backgroundColor: Colors.blue.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Optional: slight rounding
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                if (_bmi != null)
                  Text(
                    "BMI: ${_bmi!.toStringAsFixed(2)} ($_bmiResult)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                SizedBox(height: 20),

                // Final Submission
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle_outline),
                  label: Text("Submit Report"),
                  onPressed:  _isLoading ? null : _submitImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Wider but still “square-ish” in height
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )

    );
  }

  TableRow _buildTableRow(
      String label, TextEditingController controller, IconData icon) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [Icon(icon, size: 18), SizedBox(width: 6), Text(label)],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 0,
          child: TextFormField(
            controller: controller,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ),
    ]);
  }
}

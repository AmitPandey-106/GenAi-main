import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SanitationInspect extends StatefulWidget {
  @override
  _SanitationInspectState createState() => _SanitationInspectState();
}

class _SanitationInspectState extends State<SanitationInspect> {
  File? _image;
  bool _isSubmitEnabled = false;
  String? _selectedDate;
  String? _selectedTime;
  String? _fileName;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _submitImage() async {
    if (_image == null && _selectedDate == null && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://prathamesh901-sanitization-api2.hf.space/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', _image!.path),
    );

    print("🚀 Sending sanitization request to server...");

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("Server responded with status: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseBody);

        if (jsonData.containsKey('prediction')) {
          String predictionResult = jsonData['prediction'];
          String predictionResultUrl = jsonData['image_url'];// 'Good' or 'Bad'

          // Get UDISE number from SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var udise = prefs.getString('udise');
          var collegeName = prefs.getString('collegeName');

          DateTime now = DateTime.now();
          String formattedDate = "${now.year}-${now.month}-${now.day}";
          String formattedTime = "${now.hour}:${now.minute}";

          // Save this sanitization prediction in Firebase
          DatabaseReference dbRef = FirebaseDatabase.instance
              .ref("GenAi")
              .child("sanitization_detections");

          await dbRef.push().set({
            "udise": udise,
            "collegeName": collegeName,
            "ImageUploadedDate": formattedDate,
            "ImageUploadedTime": formattedTime,
            "SelectedImageUploadedDate": _selectedDate,
            "SelectedImageUploadedTime": _selectedTime,
            "prediction_result": predictionResult,
            "predictionResultUrl":predictionResultUrl,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sanitization prediction saved successfully")),
          );

          print("✅ Sanitization Result Saved: $predictionResult");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid response format")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please check the API or image size")),
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
        title: Text("Sanitation Inspection", style: TextStyle(color: Colors.white, fontSize: 20),),
        backgroundColor: Colors.lightBlue,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sanitation and Hygiene Inspection",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Upload images of toilets, washrooms and washbasin to assess cleanliness, detect hygiene issues, and ensure a healthy school environment.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 20),

                Row(
                  children: [
                    Icon(Icons.event, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text("Select Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: ElevatedButton(
                              onPressed: _selectDate,
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // Ensures content fits inside the button
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today, size: 24), // Calendar Icon
                                    if (_selectedDate != null) ...[ // ✅ Corrected condition
                                      SizedBox(width: 8),
                                      Text(_selectedDate!, style: TextStyle(fontSize: 16)), // ✅ Corrected variable
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: ElevatedButton(
                              onPressed: _selectTime,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.access_time, size: 24), // Time Icon
                                    if (_selectedTime != null) ...[ // ✅ Corrected condition
                                      SizedBox(width: 8),
                                      Text(_selectedTime!, style: TextStyle(fontSize: 16)), // ✅ Corrected variable
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                Row(
                  children: [
                    Icon(Icons.image, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text("Upload Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.lightBlueAccent, width: 1),
                        color: Colors.grey.shade100,
                        image: _image != null
                            ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _image == null
                          ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: Colors.blueAccent),
                              SizedBox(height: 10),
                              Text("Tap to upload image", style: TextStyle(color: Colors.black54))
                            ],
                          ))
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                if (_image != null)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blueAccent),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _fileName!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Date: ${_selectedDate ?? "-"}  |  Time: ${_selectedTime ?? "-"}",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),

                Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:  _isLoading ? null : _submitImage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child:  _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        :
                    Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

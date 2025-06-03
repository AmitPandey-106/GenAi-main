import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodInspect extends StatefulWidget {
  @override
  _FoodInspectState createState() => _FoodInspectState();
}

class _FoodInspectState extends State<FoodInspect> {
  File? _image;
  String? _selectedDate;
  String? _selectedTime;
  String? _fileName;
  String? udise;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Set<String> _previouslySelectedDates = {}; // Store selected dates

  @override
  void initState() {
    super.initState();
    _fetchPreviouslySelectedDates(); // Load previous dates
  }

  Future<void> _fetchPreviouslySelectedDates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    udise = prefs.getString('udise');

    DatabaseReference dbRef = FirebaseDatabase.instance.ref("GenAi").child("members").child(udise!).child("food_detections");

    DataSnapshot snapshot = await dbRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _previouslySelectedDates = data.keys.map((key) => key.toString()).toSet();
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
      });
    }
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        // Disable previously selected dates
        return !_previouslySelectedDates.contains(DateFormat('yyyy-MM-dd').format(date));
      },
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      String dayOfWeek = DateFormat('EEEE').format(picked);

      if (_previouslySelectedDates.contains(formattedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This date has already been selected! Choose another.")),
        );
        return;
      }

      setState(() {
        _selectedDate = "$formattedDate ($dayOfWeek)";
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
      Uri.parse('https://prathamesh901-food-detection.hf.space/food/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', _image!.path),
    );

    print("🚀 Sending request to server...");

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("Server responded with status: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseBody);

        if (jsonData.containsKey('annotated_image_url') && jsonData.containsKey('food_quality')) {
          String annotatedImageUrl = jsonData['annotated_image_url'];
          String foodQuality = jsonData['food_quality'];
          Map<String, dynamic> nutritionalSummary = Map<String, dynamic>.from(jsonData['nutritional_summary']);
          Map<String, dynamic> total = Map<String, dynamic>.from(jsonData['total']);

          String resultText = "🛡 *Food Quality:* $foodQuality\n\n";
          resultText += "🍽 *Nutritional Summary:*\n";

          nutritionalSummary.forEach((key, value) {
            resultText += "✅ $key - Calories: ${value['calories']}, Carbs: ${value['carbs']}g, Fat: ${value['fat']}g, Protein: ${value['protein']}g\n";
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          udise = prefs.getString('udise');
          DatabaseReference dbRef = FirebaseDatabase.instance.ref("GenAi").child("members").child(udise!).child("food_detections").child(_selectedDate!);

          DateTime now = DateTime.now();
          String formattedDate = "${now.year}-${now.month}-${now.day}";
          String formattedTime = "${now.hour}:${now.minute}:${now.second}";

          await dbRef.set({
            "udise":udise,
            "ImageUploadedDate": formattedDate,
            "ImageUplaodedTime": formattedTime,
            "SelectedImageUploadedDate": _selectedDate,
            "SelectedImageUplaodedTime": _selectedTime,
            "annotated_image_url": annotatedImageUrl,
            "food_quality": foodQuality,
            "nutritional_summary": nutritionalSummary,
            "total": total,
          });

          final url = Uri.parse('https://notificationstuff.onrender.com/send');
          final serv = "Food inspection";
          final msg =
              "User $udise has requested for $serv Service for $formattedDate";
          final td = {'title': "🔔 Food Inspection", 'body': msg};
          try {
            final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(td),
            );
            if (response.statusCode == 200) {
              print('Title and Body sent successfully!');
            } else {
              print('Failed to send Title and Body: ${response.body}');
            }
          } catch (e) {
            print('Error: $e');
          }

          print("ResultOfImage: $resultText");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Data Has been Sent to Cluster")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid response format")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please Compress the Image Size")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
      );
    }
    finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Inspection", style: TextStyle(color: Colors.white, fontSize: 20),),
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
                  "Food Quality Inspection",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Upload a photo of the food to check its quality, predict the type, and estimate calories.",
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

                // Image Upload Section
                Row(
                  children: [
                    Icon(Icons.image, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text("Upload Food Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

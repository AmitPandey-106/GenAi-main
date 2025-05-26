import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddMemberPage extends StatefulWidget {
  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController searchController = TextEditingController();
  bool _isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref("GenAi").child("members");

  List<Map<String, String>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  void _fetchMembers() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data is List) {
        setState(() {
          members = [];
          for (int i = 0; i < data.length; i++) {
            if (data[i] != null && data[i] is Map) {
              members.add({
                'udise': i.toString(),
                'college': data[i]['college']?.toString() ?? 'Unknown',
                'password': data[i]['password']?.toString() ?? ''
              });
            }
          }
          _isLoading = false; // Stop loading after data is fetched
        });
      } else if (data is Map) {
        setState(() {
          members = data.entries.map((e) {
            final memberData = e.value as Map?;
            return {
              'udise': e.key.toString(),
              'college': memberData?['college']?.toString() ?? 'Unknown',
              'password': memberData?['password']?.toString() ?? ''
            };
          }).toList();
          _isLoading = false; // Stop loading after data is fetched
        });
      } else {
        setState(() {
          members = [];
          _isLoading = false; // Stop loading if no data is found
        });
      }
    });
  }


  Future<bool> _isUdiseUnique(String udise) async {
    final snapshot = await _database.child(udise).get();
    return !snapshot.exists;
  }

  void _addOrUpdateMember(String udise, String college, String password ,{bool isEdit = false}) async {
    if (!isEdit) {
      // Check if UDISE is unique before adding
      bool unique = await _isUdiseUnique(udise);
      if (!unique) {
        _showConfirmationDialog("UDISE number already exists!");
        return;
      }
    }

    _database.child(udise).set({'UDISE':udise,'college': college, 'password': password, 'role':'user'}).then((_) {
      _showConfirmationDialog(isEdit ? "Member updated successfully!" : "Member added successfully!");
    }).catchError((error) {
      _showConfirmationDialog("Failed to process request.");
    });
  }

  void _showAddMemberDialog({Map<String, String>? member}) {
    TextEditingController udiseController = TextEditingController(text: member?['udise'] ?? '');
    TextEditingController collegeController = TextEditingController(text: member?['college'] ?? '');
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(member == null ? 'Add Member' : 'Edit Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: udiseController,
                decoration: InputDecoration(labelText: 'UDISE Number'),
                enabled: member == null, // Disable editing UDISE when updating
              ),
              TextField(
                controller: collegeController,
                decoration: InputDecoration(labelText: 'College Name'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                String udise = udiseController.text.trim();
                String college = collegeController.text.trim();
                String password = passwordController.text;
                String confirmPassword = confirmPasswordController.text;

                if (udise.isEmpty || college.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  _showConfirmationDialog("All fields are required.");
                  return;
                }
                if (password != confirmPassword) {
                  _showConfirmationDialog("Passwords do not match.");
                  return;
                }

                _addOrUpdateMember(udise, college, password, isEdit: member != null);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Members", style: TextStyle(color: Colors.white, fontSize: 20),),
        backgroundColor: Colors.lightBlue,
      ),
      body:Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by UDISE or College Name',
                          labelStyle: TextStyle(color: Colors.blue, fontSize: 16), // Blue label text
                          hintText: 'Enter UDISE or College Name',
                          hintStyle: TextStyle(color: Colors.blue.shade300), // Light blue hint text
                          prefixIcon: Icon(Icons.search, color: Colors.blue), // Search icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                            borderSide: BorderSide(color: Colors.blue, width: 2), // Blue border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white, // White background
                        ),
                        style: TextStyle(color: Colors.black, fontSize: 16), // Black text
                        onChanged: (value) => setState(() {}),
                      )
            
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _showAddMemberDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue background
                        foregroundColor: Colors.white, // White text color
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Spacing
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        elevation: 5, // Shadow effect
                      ),
                      child: Text(
                        'Add Member',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
            
                  ],
                ),
                SizedBox(height: 20),
                 _isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.blue))
                  : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      border: TableBorder.all(),
                      columns: [
                        DataColumn(label: Text('UDISE Number')),
                        DataColumn(label: Text('College Name')),
                        DataColumn(label: Text('Edit')),
                      ],
                      rows: members
                          .where((member) =>
                      member['udise']!.contains(searchController.text) ||
                          member['college']!.toLowerCase().contains(searchController.text.toLowerCase()))
                          .map((member) => DataRow(cells: [
                        DataCell(Text(member['udise']!)),
                        DataCell(Text(member['college']!)),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _showAddMemberDialog(member: member),
                            child: Text('Edit'),
                          ),
                        ),
                      ]))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
    );
  }
}

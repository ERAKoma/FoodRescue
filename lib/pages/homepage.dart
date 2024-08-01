import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:food_rescue/models/rescue_model.dart';
import 'package:food_rescue/provider/user_provider.dart';
import 'package:food_rescue/pages/rescues_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Rescue> _rescues = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ImagePicker _picker = ImagePicker();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchrescues();
  }

  Future<void> _fetchrescues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await http.get(Uri.parse('http://172.16.7.195:8080/get_rescues'));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _rescues = jsonResponse
              .map((data) => Rescue.fromJson(data as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load rescues.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching rescues: $e';
      });
    }
  }

  DateTime? _selectedDateTime;

  Future<void> pickDateTime(
      BuildContext context, StateSetter setModalState) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setModalState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dateTimeController.text =
              DateFormat('dd MM yyyy HH:mm').format(_selectedDateTime!);
        });
      }
    }
  }

  Future<void> _createRescue() async {
    // Ensure all required fields are filled before creating an rescue
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        dateTimeController.text.isEmpty ||
        locationController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _showAlert('Missing Information', 'Please fill out all fields.');
      return;
    }

    var uuid = const Uuid();
    String rescueId = uuid.v4();
    String userEmail =
        Provider.of<UserProvider>(context, listen: false).user?.email ?? "";

    var response = await http.post(
      Uri.parse('http://172.16.7.195:8080/create_rescue'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'rescue_id': rescueId,
        'title': titleController.text,
        'desc': descriptionController.text,
        'date': dateTimeController.text,
        'location': locationController.text,
        'email': userEmail,
        'phone': phoneController.text,
        'image': 'assets/images/rescue.jpeg', // Default image path
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(
          context); // Dismiss the bottom sheet right after successful creation
      _promptForImageUpload(rescueId); // Then prompt for image upload
      _resetFormFields(); // Reset the form fields for next use
      _fetchrescues(); // Refresh the list of rescues
    } else {
      _showAlert(
          'Failed to Create rescue', 'Something went wrong. Please try again.');
    }
  }

  void _promptForImageUpload(String rescueId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  _getImage(ImageSource.camera, rescueId);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  _getImage(ImageSource.gallery, rescueId);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Skip Image Upload'),
                onTap: () {
                  Navigator.pop(
                      context); // Close the menu without uploading an image
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source, String rescueId) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      var uri =
          Uri.parse('http://172.16.7.195:8080/upload_rescue_pic/$rescueId');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        _showAlert('Image Uploaded', 'The image was successfully uploaded.');
      } else {
        _showAlert('Upload Failed', 'Failed to upload image.');
      }
    } else {
      _showAlert('Image Upload Canceled', 'No image was selected.');
    }
  }

  void _showForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines:
                            5, // Set this to a higher number for more lines
                      ),
                      TextField(
                        controller: dateTimeController,
                        decoration: InputDecoration(labelText: 'Date'),
                        onTap: () => pickDateTime(context, setModalState),
                      ),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(labelText: 'Location'),
                      ),
                      TextField(
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                        decoration: InputDecoration(labelText: 'Phone'),
                      ),
                      ElevatedButton(
                        onPressed: _createRescue,
                        child: Text('Post Food Rescue'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Reset the form fields when the bottom sheet is dismissed
      _resetFormFields();
    });
  }

  void _resetFormFields() {
    titleController.clear();
    descriptionController.clear();
    dateTimeController.clear();
    locationController.clear();
    phoneController.clear();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateTimeController.dispose();
    locationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90.0),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Browse the available rescues',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const Spacer(),
                    const Spacer(),
                    Image.asset(
                      'assets/images/Logo.png',
                      height: 60,
                      fit: BoxFit.fitHeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchrescues,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _rescues.length,
                    itemBuilder: (context, index) {
                      final rescue = _rescues[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RescueDetailPage(rescue: rescue),
                              ),
                            );
                          },
                          child: HomepageCard(
                            imagePath: rescue.image,
                            title: rescue.title,
                            description: rescue.desc,
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

//This class is meant to hold the data for the each location and to be used and create a card for them
class HomepageCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const HomepageCard({
    required this.imagePath,
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          imagePath.startsWith('assets/')
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    maxLines: 2, // Limit descriptions 2 lines
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

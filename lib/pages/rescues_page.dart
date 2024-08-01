import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:food_rescue/models/rescue_model.dart';
import 'package:food_rescue/provider/user_provider.dart';

class RescueDetailPage extends StatefulWidget {
  final Rescue rescue;

  const RescueDetailPage({super.key, required this.rescue});

  @override
  RescueDetailPageState createState() => RescueDetailPageState();
}

class RescueDetailPageState extends State<RescueDetailPage> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late TextEditingController locationController;
  late TextEditingController phoneController;
  late Rescue _updatedRescue;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.rescue.title);
    descriptionController = TextEditingController(text: widget.rescue.desc);
    dateController = TextEditingController(text: widget.rescue.date);
    locationController = TextEditingController(text: widget.rescue.location);
    phoneController = TextEditingController(text: widget.rescue.phone);
    _updatedRescue = widget.rescue;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    locationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _formattedDate(String date) {
    DateTime parsedDate = DateFormat('dd MM yyyy h:mm').parse(date);
    return DateFormat('MMMM dd, yyyy h:mm a').format(parsedDate);
  }

  Future<void> _editrescue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      _showAlert('Error', 'No user logged in');
      return;
    }

    final response = await http.put(
      Uri.parse('http://172.16.7.195:8080/update_rescue'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'rescue_id': _updatedRescue.rescue_id,
        'title': titleController.text,
        'desc': descriptionController.text,
        'date': dateController.text,
        'location': locationController.text,
        'phone_number': phoneController.text,
        'image': _updatedRescue.image,
      }),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (response.statusCode == 200) {
      Navigator.pop(context);
      _showAlert('Success', 'Rescue updated successfully!');
    } else {
      _showAlert('Error', 'Failed to update rescue.');
    }
  }

  Future<void> _deleterescue() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final response = await http.delete(
      Uri.parse(
          'http://172.16.7.195:8080/delete_rescue/${widget.rescue.rescue_id}'),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (response.statusCode == 200) {
      Navigator.pop(context);
      _showAlert('Success', 'rescue deleted successfully!');
    } else {
      _showAlert('Error', 'Failed to delete rescue.');
    }
  }

  void _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('dd MM yyyy h:mm').format(picked);
      });
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
                title: Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  _removeImage(rescueId);
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
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _updatedRescue =
                _updatedRescue.copyWith(image: responseData['file_url']);
          });
        }
        _showAlert('Image Uploaded', 'The image was successfully uploaded.');
      } else {
        _showAlert('Upload Failed', 'Failed to upload image.');
      }
    } else {
      _showAlert('Image Upload Canceled', 'No image was selected.');
    }
  }

  Future<void> _removeImage(String rescueId) async {
    if (mounted) {
      setState(() {
        _updatedRescue =
            _updatedRescue.copyWith(image: 'assets/images/rescue.jpeg');
      });
    }

    final response = await http.put(
      Uri.parse('http://172.16.7.195:8080/update_rescue'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'rescue_id': _updatedRescue.rescue_id,
        'image': 'assets/images/rescue.jpeg',
      }),
    );

    if (response.statusCode == 200) {
      _showAlert('Success', 'Image removed successfully!');
    } else {
      _showAlert('Error', 'Failed to remove image.');
    }
  }

  void _showEditForm(BuildContext context) {
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(labelText: 'Title'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: descriptionController,
                          decoration: InputDecoration(labelText: 'Description'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: dateController,
                          decoration: InputDecoration(labelText: 'Date'),
                          onTap: () => _pickDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a date';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: locationController,
                          decoration: InputDecoration(labelText: 'Location'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: phoneController,
                          decoration:
                              InputDecoration(labelText: 'Phone Number'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a phone number';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _editrescue,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text('Update rescue'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _promptForImageUpload(_updatedRescue.rescue_id),
                          child: const Text('Upload/Remove Image'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
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

  void launchPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await launchUrl(phoneUri)) {
    } else {
      // Handle the error, for example by showing a message to the user
      print('Could not launch dialer');
    }
  }

  String viewDateTime(String date) {
    DateTime parsedDate = DateFormat('dd MM yyyy h:mm').parse(date);
    return DateFormat('MMMM dd, yyyy h:mm a').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isCreator = user != null && user.email == widget.rescue.email;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.40;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // rescue Image
                      widget.rescue.image.startsWith('assets/')
                          ? Image.asset(
                              widget.rescue.image,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.rescue.image,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                            ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // rescue Title and Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.rescue.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                Text(
                                  viewDateTime(widget.rescue.date),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 149, 149, 149),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // rescue Description
                            Text(
                              widget.rescue.desc,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.location_pin,
                                    color: Colors.blue,
                                  ),
                                  label: Text(
                                    widget.rescue.location,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=${widget.rescue.location}'));
                                  },
                                ),
                                const Spacer(),
                                const Spacer(),
                                if (isCreator)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _showEditForm(context);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            //Creator of rescue text
                            Text(
                              'Created by: ${widget.rescue.email}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // rescue Phone Number with Call Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Contact Us',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      launchPhoneDialer(widget.rescue.phone);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      elevation:
                                          2, 
                                    ),
                                    child: const Icon(
                                      Icons.call,
                                    )),
                              ],
                            ),
                            if (isCreator)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _deleterescue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        textStyle:
                                            const TextStyle(fontSize: 18),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            )
                                          : const Text('Delete rescue'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

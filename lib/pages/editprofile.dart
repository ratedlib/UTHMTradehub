import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facultyController = TextEditingController();
  final _yearController = TextEditingController();
  final _semesterController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile info from Firestore
  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Load user profile data from Firestore
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          _nameController.text = userData['name'] ?? '';
          _descriptionController.text = userData['description'] ?? '';
          _facultyController.text = userData['faculty'] ?? '';
          _yearController.text = userData['yearOfStudy'] ?? '';
          _semesterController.text = userData['semester'] ?? '';
          _profileImageUrl = userData['profileImageUrl'];
        }
        setState(() {});
      } catch (e) {
        print("Error loading user profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  // Pick a profile image from the gallery
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }


  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    try {
      // Create a folder specifically for profile images
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("profile_images/$fileName"); // Folder named 'profile_images'

      print("Uploading profile image...");
      await storageRef.putFile(_profileImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });
      print("Profile image uploaded successfully!");
    } catch (e) {
      print("Error uploading profile image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }


  // Save profile changes to Firestore
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        print("Updating user display name...");
        await user.updateDisplayName(_nameController.text);

        if (_profileImageUrl != null) {
          print("Updating user photo URL...");
          await user.updatePhotoURL(_profileImageUrl);
        }

        await user.reload();

        print("Saving profile data to Firestore...");
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'faculty': _facultyController.text,
          'yearOfStudy': _yearController.text,
          'semester': _semesterController.text,
          'profileImageUrl': _profileImageUrl,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        print("Profile updated successfully!");
      } catch (e) {
        print("Error saving profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      print("No user is signed in!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Profile Image & Edit Button
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/img/default_profile.png')
                  as ImageProvider),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Information Fields
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),

                  // Description Field
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),

                  // Faculty, Year, Semester Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _facultyController,
                          decoration: const InputDecoration(labelText: 'Faculty'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          decoration: const InputDecoration(labelText: 'Year'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _semesterController,
                          decoration:
                          const InputDecoration(labelText: 'Semester'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      await _uploadProfileImage();
                      await _saveProfile();
                    },
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

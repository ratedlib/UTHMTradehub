import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile.dart';
import 'catalog.dart';
import 'sell.dart';

class SellPage extends StatefulWidget {
  const SellPage({Key? key}) : super(key: key);

  @override
  _SellPageState createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  bool _isUsed = false;
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];

  // Pick multiple images from the gallery
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  // Upload images to Firebase Storage
  Future<void> _uploadImages() async {
    for (var imageFile in _imageFiles) {
      // Generate a unique file name for each image
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child("item_images/$fileName");

      // Upload the image file
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _imageUrls.add(downloadUrl);
      });
    }
  }

  // Upload item details to Firestore
  Future<void> _uploadItem() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty || _imageUrls.isEmpty) {
      // Show a message to the user if they have not filled out the required fields
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and upload at least one image')));
      return;
    }

    // Get the current user's UID from FirebaseAuth
    final currentUser = FirebaseAuth.instance.currentUser;
    final sellerId = currentUser?.uid;

    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is logged in')));
      return;
    }

    // Add the item to Firestore with the seller's UID
    await FirebaseFirestore.instance.collection('items').add({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'category': _selectedCategory,
      'isUsed': _isUsed,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrls': _imageUrls,  // Ensure this field is stored
      'sellerId': sellerId,  // Save seller's UID instead of email
    });

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item listed successfully')));

    // Clear fields
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _imageFiles.clear();
      _imageUrls.clear();
      _selectedCategory = null;
      _isUsed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell an Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 8),
            // Item Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Item Description'),
            ),
            const SizedBox(height: 8),
            // Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 8),
            // Categories Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Electronics', 'Furniture', 'Clothing', 'Books', 'Other']
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Used/New Checkbox
            Row(
              children: [
                Text('Used'),
                Checkbox(
                  value: _isUsed,
                  onChanged: (value) {
                    setState(() {
                      _isUsed = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Pick Image Button
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Pick Images'),
            ),
            const SizedBox(height: 8),
            // Display images
            if (_imageFiles.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _imageFiles.length,
                itemBuilder: (context, index) {
                  return Image.file(
                    _imageFiles[index],
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  );
                },
              ),
            const SizedBox(height: 16),
            // Upload Item Button
            ElevatedButton(
              onPressed: () async {
                await _uploadImages(); // Upload images before saving item
                await _uploadItem(); // Upload item details to Firestore
              },
              child: const Text('Sell Item'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break; // Home already loaded
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatalogPage(), // Navigate to CatalogPage
                ),
              );
              break;
            case 2:
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}

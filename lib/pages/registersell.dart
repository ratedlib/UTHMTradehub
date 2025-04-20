import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegisterSellerPage extends StatefulWidget {
  const RegisterSellerPage({Key? key}) : super(key: key);

  @override
  _RegisterSellerPageState createState() => _RegisterSellerPageState();
}

class _RegisterSellerPageState extends State<RegisterSellerPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _idCardController = TextEditingController();

  // Track both transaction methods
  bool _isCODSelected = false;
  bool _isOnlineBankingSelected = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  // Method to save seller data to Firestore
  Future<void> _saveSellerToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      // Add seller data using UID as the document ID
      await FirebaseFirestore.instance.collection('sellers').doc(user.uid).set({
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'address': _addressController.text,
        'idCard': _idCardController.text,
        'transactionMethods': {
          'COD': _isCODSelected,
          'OnlineBanking': _isOnlineBankingSelected,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the user's document to include the sellerId
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'sellerId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      Navigator.pop(context); // Navigate back after successful registration
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }



  // Method to handle form submission
  void _registerSeller() {
    if (_formKey.currentState!.validate()) {
      _saveSellerToFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Seller'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^01[0-9]{8,10}$').hasMatch(value)) {
                        return 'Please enter a valid Malaysian phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Residential address or college
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Residential Address or College',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address or college';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Identification card number
                  TextFormField(
                    controller: _idCardController,
                    decoration: const InputDecoration(
                      labelText: 'Identification Card Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your ID card number';
                      }
                      if (!RegExp(r'^\d{2}\d{2}\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
                        return 'Please enter a valid Malaysian ID number (e.g., 020921-03-0356)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Preferred transaction method (both COD and Online Banking)
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text("Cash On Delivery"),
                          value: _isCODSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _isCODSelected = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text("Online Banking"),
                          value: _isOnlineBankingSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _isOnlineBankingSelected = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  ElevatedButton(
                    onPressed: _registerSeller,
                    child: const Text('Register as Seller'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'editprofile.dart';
import 'registersell.dart';
import 'homepage.dart';  // Import the file where HomePage is defined
import 'sell.dart';  // Import the file where SellPage is defined
import 'catalog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'error': 'No user is currently logged in'};
      }

      final uid = user.uid;

      // Fetch user data from the Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) {
        return {'error': 'User data not found in Firestore'};
      }

      // Check for seller data
      if (userData.containsKey('sellerId')) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(userData['sellerId'])
            .get();
        if (sellerDoc.exists) {
          userData['sellerData'] = sellerDoc.data();
        }
      }

      return userData;
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  void _refreshProfile() {
    setState(() {
      _userDataFuture = _fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data?['error'] != null) {
            return Center(
              child: Text(
                snapshot.data?['error'] ?? 'Error loading profile data',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            final userData = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image & Edit Button
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                              _refreshProfile();
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: userData['profileImageUrl'] != null
                                  ? NetworkImage(userData['profileImageUrl'])
                                  : const AssetImage('lib/img/default_profile.png') as ImageProvider,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                              _refreshProfile();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Profile Information Section
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              '${userData['name'] ?? 'No name provided'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Text(
                              '${userData['description'] ?? 'No description provided.'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Faculty, Year, Semester
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoCard('Faculty', userData['faculty'] ?? 'N/A'),
                                _buildInfoCard('Year', userData['yearOfStudy'] ?? 'N/A'),
                                _buildInfoCard('Semester', userData['semester'] ?? 'N/A'),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Show seller registration status
                            if (userData.containsKey('sellerData'))
                              _buildSellerBox(userData['sellerData'])
                            else
                              ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterSellerPage()),
                                  );
                                  _refreshProfile();
                                },
                                child: const Text('Register as a Seller'),
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
                  ],
                ),
              ),
            );
          }
        },
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
        onTap: (index) async {
          switch (index) {
            case 0:
            // Navigate to HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatalogPage(), // Navigate to CatalogPage
                ),
              );
              break;
            case 2:
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userData = await _fetchUserData();
                if (userData.containsKey('sellerData')) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SellPage()),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Not Registered as Seller'),
                      content: const Text('You need to register as a seller to list items.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterSellerPage()),
                            );
                          },
                          child: const Text('Register Now'),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                // Handle user not logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to continue')),
                );
              }
              break;

            case 3:
            // Stay on ProfilePage
              break;
          }
        },
      ),

    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerBox(Map<String, dynamic> sellerData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'You are a registered seller!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

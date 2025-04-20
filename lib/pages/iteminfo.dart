import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom.dart';

class ItemInfoPage extends StatelessWidget {
  final String itemId;

  const ItemInfoPage({Key? key, required this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('items').doc(itemId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Item not found.'));
          }

          final item = snapshot.data!;
          final name = item['name'];
          final description = item['description'];
          final price = item['price'];
          final isUsed = item['isUsed'];
          final sellerId = item['sellerId'];
          final timestamp = item['timestamp'].toDate();
          final category = item['category'];
          final imageUrls = List<String>.from(item['imageUrls']);

          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchSellerDetails(sellerId),
            builder: (context, sellerSnapshot) {
              if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!sellerSnapshot.hasData || sellerSnapshot.data!.isEmpty) {
                return const Center(child: Text('Seller details not found.'));
              }

              final sellerDetails = sellerSnapshot.data!;
              final sellerFullName = sellerDetails['fullName'] ?? 'Unknown Seller';
              final sellerEmail = sellerDetails['email'] ?? 'Not provided';
              final sellerPhoneNumber = sellerDetails['phoneNumber'] ?? 'Not provided';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: 350,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Item Name and Price
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM $price',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Item Details Card
                      _buildCard(
                        children: [
                          _buildInfoRow('Category:', category),
                          _buildInfoRow('Condition:', isUsed ? 'Used' : 'New'),
                          _buildInfoRow('Posted on:', '${timestamp.day}-${timestamp.month}-${timestamp.year}'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Seller Information Card
                      const Text(
                        'Seller Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        children: [
                          _buildInfoRow('Full Name:', sellerFullName),
                          _buildInfoRow('Email:', sellerEmail),
                          _buildInfoRow('Phone Number:', sellerPhoneNumber),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Chat Button
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId != null) {
                              final chatRoomId = [currentUserId, sellerId]..sort();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoomPage(
                                    chatRoomId: chatRoomId.join('_'),
                                    otherUserId: sellerId,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Chat with Seller', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Helper method to fetch seller details from both `users` and `sellers` collections
  Future<Map<String, dynamic>> _fetchSellerDetails(String sellerId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
    final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();

    if (!userDoc.exists || !sellerDoc.exists) {
      return {};
    }

    return {
      'email': userDoc.data()?['email'] ?? 'Not provided',
      'fullName': sellerDoc.data()?['fullName'] ?? 'Unknown Seller',
      'phoneNumber': sellerDoc.data()?['phoneNumber'] ?? 'Not provided',
    };
  }

  /// Card-style container for grouping information
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Information row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPage extends StatefulWidget {
  final String sellerId;
  final String itemId;

  const ReportPage({Key? key, required this.sellerId, required this.itemId}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reporterId = currentUser.uid;
    final sellerId = widget.sellerId;

    try {
      // Fetch reporter name from users collection
      final reporterSnapshot = await FirebaseFirestore.instance.collection('users').doc(reporterId).get();
      final reporterName = reporterSnapshot.data()?['name'] ?? 'Unknown';

      // Fetch reported seller name from sellers collection
      final sellerSnapshot = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();
      final sellerName = sellerSnapshot.data()?['fullName'] ?? 'Unknown';

      // Save to reported_sellers collection
      await FirebaseFirestore.instance.collection('reported_sellers').add({
        'reportedSellerId': sellerId,
        'reportedSellerName': sellerName,
        'reportedByUserId': reporterId,
        'reportedByUserName': reporterName,
        'itemId': widget.itemId,
        'reason': _reasonController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Seller')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please explain why you are reporting this seller:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your reason here...',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit Report'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

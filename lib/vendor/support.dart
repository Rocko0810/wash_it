import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/widgets/shimmer.dart';

class VendorSupportPage extends StatelessWidget {
  final String uid; // Vendor ID passed as a parameter

  VendorSupportPage({required this.uid});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: Colors.white,
        centerTitle: true,  // Centers the title
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupportHistoryPage(uid: uid),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Dimensions.Height10),
            const Text(
              'We are here to assist you with any questions or issues. Please browse our FAQs, contact us directly, or submit a support request below.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: Dimensions.Height30),
            _buildSectionTitle('Contact Us'),
            _buildContactRow(Icons.phone, 'Phone', '+91 7725895752'),
            _buildContactRow(Icons.email, 'Email', 'washitofficial20sept@gmail.com'),
            _buildContactRow(Icons.location_on, 'Address', 'WashIt HQ, Durg, India'),
            SizedBox(height: Dimensions.Height30),
            _buildSectionTitle('Frequently Asked Questions'),
            _buildFAQTile('How can I register as a vendor?', 'You can register through the Vendor Portal on our app.'),
            _buildFAQTile('How do I manage orders?', 'You can manage all orders from the Vendor Dashboard in the app.'),
            _buildFAQTile('How can I contact support?', 'Use the phone or email listed above to reach our support team.'),
            SizedBox(height: Dimensions.Height30),
            _buildSectionTitle('Submit a Support Request'),
            _buildSupportForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(width: Dimensions.Width10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(content, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(answer, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSupportForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _issueController,
            decoration: InputDecoration(
              labelText: 'Issue',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radius30)),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter the issue' : null,
          ),
          SizedBox(height: Dimensions.Height20),
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              labelText: 'Contact Info (Email or Phone)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radius30)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please provide contact information';
              if (!_isValidContact(value)) return 'Enter a valid email or 10-digit phone number';
              return null;
            },
          ),
          SizedBox(height: Dimensions.Height20),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radius30)),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter the description' : null,
          ),
          SizedBox(height: Dimensions.Height20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submitSupportRequest(
                    _issueController.text,
                    _contactController.text,
                    _descriptionController.text,
                  );
                  ScaffoldMessenger.of(_formKey.currentContext!).showSnackBar(
                    const SnackBar(content: Text('Support request submitted')),
                  );
                  _clearFields();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: Dimensions.Width30, vertical: Dimensions.Height10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radius30)),
              ),
              child: const Text('Submit Request', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _issueController.clear();
    _contactController.clear();
    _descriptionController.clear();
  }

  bool _isValidContact(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return emailRegex.hasMatch(value) || phoneRegex.hasMatch(value);
  }

  void _submitSupportRequest(String issue, String contact, String description) {
    final requestData = {
      'issue': issue,
      'contact': contact,
      'description': description,
      'uid': uid,  // Store vendor ID for reference in the global collection
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Add to vendor's subcollection under `vendors`
    FirebaseFirestore.instance
        .collection('vendors')
        .doc(uid)
        .collection('vendorSupport')
        .add(requestData)
        .then((_) {
      print('Support request added to vendor subcollection');
    }).catchError((error) {
      print('Failed to add to vendor subcollection: $error');
    });

    // 2. Add to the central `vendorSupport` collection
    FirebaseFirestore.instance
        .collection('vendorSupport')
        .add(requestData)
        .then((_) {
      print('Support request added to central collection');
    }).catchError((error) {
      print('Failed to add to central collection: $error');
    });
  }

}

class SupportHistoryPage extends StatelessWidget {
  final String uid;

  SupportHistoryPage({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.white,
        centerTitle: true,  // Centers the title
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('vendorSupport')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ShimmerLoading());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No support requests found.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];
              return ListTile(
                title: Text(data['issue']),
                subtitle: Text(data['description']),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wash_it/Dimensions/dimensions.dart';

class RequestCallPage extends StatefulWidget {
  @override
  _RequestCallPageState createState() => _RequestCallPageState();
}

class _RequestCallPageState extends State<RequestCallPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to submit the call request to Firestore
  Future<void> submitCallRequest() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('requestCalls')
          .doc(user.uid);

      try {
        Map<String, dynamic> callRequestData = {
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'reason': _reasonController.text.trim(),
          'requestedAt': Timestamp.now(),
        };

        await userDoc.set({
          'userId': user.uid,
          'callRequests': FieldValue.arrayUnion([callRequestData])
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call request submitted successfully!')),
        );

        // Clear form fields
        _nameController.clear();
        _phoneController.clear();
        _reasonController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit call request: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to submit a request.')),
      );
    }
  }

  // Method to retrieve the user's call requests
  Stream<DocumentSnapshot> _getUserRequests() {
    User? user = _auth.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('requestCalls')
          .doc(user.uid)
          .snapshots();
    }
    throw FirebaseAuthException(message: 'No user is logged in', code: 'NO_USER');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request a Call', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white38],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Request a Call',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.Height20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: Dimensions.Height10),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    isPhone: true,
                  ),
                  SizedBox(height: Dimensions.Height10),
                  _buildTextField(
                    controller: _reasonController,
                    label: 'Reason for Call',
                    icon: Icons.report_problem,
                  ),
                  SizedBox(height: Dimensions.Height20),
                  _buildSubmitButton(),
                ],
              ),
            ),
            SizedBox(height: Dimensions.Height20),
            Text('Your Call Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _getUserRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('No requests found', style: TextStyle(color: Colors.white)));
                  }

                  List<dynamic> callRequests = snapshot.data!['callRequests'] ?? [];

                  return ListView.builder(
                    itemCount: callRequests.length,
                    itemBuilder: (context, index) {
                      var request = callRequests[index];
                      return _buildRequestCard(request);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build input fields with icons and styles
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        } else if (isPhone && !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
          return 'Please enter a valid 10-digit phone number';
        }
        return null;
      },
    );
  }

  // Build the submit button with custom styling
  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical:10,horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          submitCallRequest();
        }
      },
      child: Text('Submit Request', style: TextStyle(fontSize: 15 , color: Colors.white)),
    );
  }

  // Build a card to display the user's requests
  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: ListTile(
        title: Text('Reason: ${request['reason']}'),
        subtitle: Text(
          'Phone: ${request['phoneNumber']}\nRequested At: ${(request['requestedAt'] as Timestamp).toDate()}',
        ),

      ),
    );
  }
}

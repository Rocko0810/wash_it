import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/shimmer.dart';

class SubmitHelpTicketPage extends StatefulWidget {
  @override
  _SubmitHelpTicketPageState createState() => _SubmitHelpTicketPageState();
}

class _SubmitHelpTicketPageState extends State<SubmitHelpTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _issueController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit help ticket to Firestore
  Future<void> submitHelpTicket() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not authenticated. Please log in.')),
        );
        return;
      }

      // Help ticket data
      final ticketData = {
        'userid': user.uid,
        'name': _nameController.text,
        'email': _emailController.text,
        'issue': _issueController.text,
        'submittedAt': Timestamp.now(),
      };

      // Store in the user's sub-collection: users/{userId}/helpticket
      final userTicketRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('helpticket');

      await userTicketRef.add(ticketData);

      // Also store in the top-level 'helpticket' collection
      final globalTicketRef = FirebaseFirestore.instance.collection('helpticket');
      await globalTicketRef.add(ticketData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket submitted successfully!')),
      );

      // Clear the form fields
      _nameController.clear();
      _emailController.clear();
      _issueController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit ticket: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Help Ticket', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white54],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Submit Your Issue',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildTextField(_nameController, 'Name', Icons.person),
              SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', Icons.email, isEmail: true),
              SizedBox(height: 10),
              _buildTextField(
                _issueController,
                'Describe your issue',
                Icons.report_problem,
                maxLines: 5,
              ),
              SizedBox(height: 20),
              _buildSubmitButton(),
              SizedBox(height: 20),
              _buildHistoryButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isEmail = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        } else if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          submitHelpTicket();
        }
      },
      child: Text('Submit Ticket', style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketHistoryPage()),
        );
      },
      child: Text('View Ticket History', style: TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}

class TicketHistoryPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white54],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: user == null
            ? Center(
          child: Text(
            'User is not authenticated. Please log in.',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('helpticket')
              .orderBy('submittedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: ShimmerLoading());
            }

            final tickets = snapshot.data?.docs;

            if (tickets == null || tickets.isEmpty) {
              return Center(
                child: Text(
                  'No tickets found.',
                  style: TextStyle(color: Colors.black),
                ),
              );
            }

            return ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticketData = tickets[index].data() as Map<String, dynamic>;

                return Card(
                  color: Colors.white.withOpacity(0.8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      'Issue: ${ticketData['issue']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      'Submitted At: ${ticketData['submittedAt'].toDate()}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    //trailing:
                   //Icon(Icons.arrow_forward_ios, color: Colors.deepPurpleAccent),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

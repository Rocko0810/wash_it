import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../no_internet.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription _internetConnectionStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to the internet connection status
    _internetConnectionStreamSubscription =
        InternetConnection().onStatusChange.listen(
              (event) {
            if (event == InternetStatus.disconnected) {
              _navigateToNoInternetPage();
            }
          },
          onError: (error) {
            debugPrint("Internet connection stream error: $error");
          },
        );
  }

  void _navigateToNoInternetPage() {
    // Navigate to the NoConnectionPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const NoConnectionPage(),
      ),
    );
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription.cancel();
    super.dispose();
  }


  // Function to send password reset email
  Future<void> _sendResetPasswordEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decoration
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Go Back Icon in stylish way
          Positioned(
            top: 40,
            left: 19,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Go back action
              },
              child: Container(
                padding: EdgeInsets.all(10),

                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, size: 80, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendResetPasswordEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

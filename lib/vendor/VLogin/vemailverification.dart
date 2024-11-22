import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'vloginscreen.dart';



class VendorEmailVerificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with a similar color as the signup screen
          Container(
            decoration: const BoxDecoration(
              color: Color(0xff98b6c1),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'Please verify your email address. Check your inbox for a verification email.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        await user?.reload();
                        if (user?.emailVerified ?? false) {
                          // Update the Firestore document
                          await FirebaseFirestore.instance.collection('vendors').doc(user?.uid).update({
                            'isEmailVerified': true,
                          });

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => LoginVendor()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email not verified yet.')),
                          );
                        }
                      },
                      child: Text('I have verified my email'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        await user?.sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Verification email resent.'),
                        ));
                      },
                      child: Text('Resend Verification Email'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

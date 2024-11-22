import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wash_it/vendor/VLogin/Vsignup.dart';
import 'package:wash_it/widgets/shimmer.dart';
import '../../Dimensions/dimensions.dart';
import '../dashboardscreen.dart';
import 'Vforgotpassward.dart';
import 'dart:async'; // Import this to use TimeoutException

class LoginVendor extends StatefulWidget {
  @override
  _LoginVendorState createState() => _LoginVendorState();
}

class _LoginVendorState extends State<LoginVendor> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeFCMTokenListener();
  }

  void _initializeFCMTokenListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _storeTokenInFirestore(currentUser.uid, newToken);
      }
    }).onError((error) {
      _showError('Failed to refresh FCM token. Please try again later.');
    });
  }

  Future<void> _storeTokenInFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(uid).set(
        {
          'fcmToken': token,
          'tokenTimestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      _showError('Error storing FCM token. Please contact support.');
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Close the keyboard
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        // Timeout handling to prevent long waits
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        )
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        });

        String? uid = userCredential.user?.uid;
        if (uid != null) {
          String? token = await _firebaseMessaging.getToken();
          if (token != null) {
            await _storeTokenInFirestore(uid, token);
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                uid: uid,
                orderId: 'default_order_id',
              ),
            ),
          );
        } else {
          _showError('Unable to retrieve user information.');
        }
      } on TimeoutException catch (_) {
        _showError('Connection timed out. Please check your network.');
      } on FirebaseAuthException catch (e) {
        _showError(_mapFirebaseError(e));
      } catch (e) {
        _showError('An unexpected error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'Your account has been disabled. Contact support.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const ShimmerLoading()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              SizedBox(height: Dimensions.Height10 * 2),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VendorForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorSignupPage(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

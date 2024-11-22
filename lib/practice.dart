import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/vendor/VLogin/vloginscreen.dart';
import '../pages/home/main_wash_it_page.dart';
import 'login page/emailverification.dart';
import 'login page/forgot.dart';
import 'login page/signup.dart';

class LoginUser extends StatefulWidget {
  @override
  _LoginUserState createState() => _LoginUserState();
}

class _LoginUserState extends State<LoginUser> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? userId; // Holds the current user's ID

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to retrieve and update FCM token with recent update time
  Future<void> _retrieveFcmToken(String userId) async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken != null) {
        await userDocRef.update({
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('New FCM Token stored: $fcmToken');
      } else {
        print('Failed to retrieve FCM token.');
      }
    } catch (e, stack) {
      print('Error retrieving or updating FCM token: $e');
      print(stack);
      // Log error to Crashlytics for production
      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      User? user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;

        await _handleUserData(user);
        await _retrieveFcmToken(user.uid); // Update FCM token on Google Sign-In

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainWashIt()),
        );
      }
    } catch (e) {
      _showScaffoldMessage('Google Sign-In failed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.signInWithCredential(credential);

      User? user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;

        await _handleUserData(user);
        await _retrieveFcmToken(user.uid); // Update FCM token on Apple Sign-In

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainWashIt()),
        );
      }
    } catch (e) {
      _showScaffoldMessage('Apple Sign-In failed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || !_isValidEmail(_emailController.text.trim())) {
      _showScaffoldMessage('Please enter a valid email address.');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showScaffoldMessage('Password cannot be empty.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        userId = user.uid;

        if (!user.emailVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
          );
          return;
        }

        DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        // Ensure that the profile picture field is set to null if it doesn't exist
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null && !userData.containsKey('profilePicture')) {
          await userDocRef.update({'profilePicture': null});
        }

        await _retrieveFcmToken(user.uid); // Update FCM token on regular login

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainWashIt()),
        );
      }
    } catch (e) {
      _showScaffoldMessage('Login failed. Check your Email and Password.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUserData(User user) async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      String displayName = user.displayName ?? "No Name";
      String email = user.email ?? "No Email";

      if (!userSnapshot.exists) {
        await userDoc.set({
          'name': displayName,
          'phone': 'N/A',
          'dob': 'N/A',
          'gender': null,
          'email': email,
          'userId': userId,
          'profilePicture': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in with: $displayName')),
      );
    } catch (e, stackTrace) {
      print('Failed to handle user data: $e');
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  // Email Validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");

    return emailRegex.hasMatch(email);
  }

  // Show SnackBar Message
  void _showScaffoldMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: Dimensions.Height30*2,
        width: Dimensions.Width30*2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Image.asset(
          imagePath,
          height: Dimensions.Height30*2,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xff98b6c1),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Welcome to WashIt!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10*2),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    autofillHints: [AutofillHints.email], // Autofill email
                  ),
                  SizedBox(height: Dimensions.Height10*2),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    autofillHints: [AutofillHints.password], // Autofill password
                  ),
                  SizedBox(height: Dimensions.Height10*2),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10*2),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialLoginButton(
                        imagePath: "assets/image/google1.png",
                        onPressed: _signInWithGoogle,
                      ),
                      _buildSocialLoginButton(
                        imagePath: "assets/image/apple.png",
                        onPressed: _signInWithApple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Signup()),
                      );
                    },
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginVendor()),
                      );
                    },
                    child: const Text(
                      'Join as a partner ! ',
                      style: TextStyle(
                        color: Colors.white,
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

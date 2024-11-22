import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/login%20page/login.dart';
import 'package:wash_it/pages/menu/Aboutus.dart';
import 'package:wash_it/pages/menu/address.dart';
import 'package:wash_it/pages/menu/support/comming%20soon.dart';
import 'package:wash_it/pages/menu/support/customersupport.dart';
import 'package:wash_it/pages/menu/yourorder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'dart:math';
import '../userDetails/detailcard.dart';
import 'notification.dart';

class CircularTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle textStyle;

  CircularTextPainter(
      {required this.text, required this.radius, required this.textStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final totalAngle = 2 * pi;
    final perCharAngle = totalAngle / text.length;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      textPainter.text = TextSpan(text: char, style: textStyle);
      textPainter.layout();

      final angle = i * perCharAngle - pi / 2;
      final x = size.width / 2 + radius * cos(angle) - textPainter.width / 2;
      final y = size.height / 2 + radius * sin(angle) - textPainter.height / 2;

      canvas.save();
      canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
      canvas.rotate(angle + pi / 2);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CircularTextPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.radius != radius;
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;

  const FullScreenImagePage({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: CircleAvatar(
          radius: Dimensions.radius20 * 8, // Circle size control
          backgroundColor: Colors.grey[300], // Softer background color for better aesthetics
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: Dimensions.radius20 * 16, // Matches the circle size (2 * radius)
              height: Dimensions.radius20 * 16,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.error,
                color: Colors.red,
                size: Dimensions.radius20 * 4, // Icon if the image fails to load
              ),
            )
                : Image.asset(
              'assets/profile_picture.jpg',
              fit: BoxFit.cover,
              width: Dimensions.radius20 * 16, // Same size to maintain consistency
              height: Dimensions.radius20 * 16,
            ),
          ),
        ),
      ),
    );
  }
}

class UserMenuPage extends StatefulWidget {
  const UserMenuPage({Key? key}) : super(key: key);

  @override
  _UserMenuPageState createState() => _UserMenuPageState();
}

class _UserMenuPageState extends State<UserMenuPage> {
  User? user;
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchUserDetails();
  }

  // Fetch user details from Firestore
  Future<void> fetchUserDetails() async {
    if (user != null) {
      setState(() {
        isLoading = true; // Start loading when fetching data
      });
      try {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            userDetails = snapshot.data();
            isLoading = false;
          });
        } else {
          print('User not found');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching user details: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NotificationPage()),
              );
            },
          ),
         /* IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),*/
        ],
      ),
      body: isLoading
          ? Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: Dimensions.radius10*5,
                backgroundColor: Colors.grey,
              ),
              SizedBox(height: Dimensions.Height20),
              Container(
                width: Dimensions.Width200,
                height: Dimensions.Height20,
                color: Colors.grey,
              ),
              SizedBox(height: Dimensions.Height10),
              Container(
                width: Dimensions.Width30*5,
                height: Dimensions.Height20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchUserDetails, // Trigger data refresh when pulled
        child: SingleChildScrollView(
          // Changed to make the page scrollable
          physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling even if content is less
          child: Column(
            children: [
              // Profile Picture and Info
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to full screen image page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImagePage(
                              imageUrl: userDetails?['profilePicture'] ??
                                  'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/profile_pictures%2Fprofile001.png?alt=media&token=d45b08ab-bb2f-49aa-81d1-fc6376776cd3', // Use the default image if profile picture is null // Pass the image URL
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(200, 200),
                            painter: CircularTextPainter(
                              text: " - One Step To Clean - Washit",
                              radius: Dimensions.radius20*4,
                              textStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Container(
                            width: Dimensions.Width200/2,
                            height: Dimensions.Height20*5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: userDetails?['profilePicture'] != null
                                    ? NetworkImage(userDetails!['profilePicture'])
                                    : NetworkImage(
                                    "https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/profile_pictures%2Fprofile001.png?alt=media&token=d45b08ab-bb2f-49aa-81d1-fc6376776cd3"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Dimensions.Height10),
                    // Display User Name
                    Text(
                      userDetails?['name'] ?? 'N/A',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: Dimensions.Height10/2),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.Height20),

              // List of options
              ListView(
                shrinkWrap: true, // Shrink the ListView so it fits within the Column
                physics: NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
                children: [
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text("Your orders"),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrdersPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Account details"),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DetailsCardPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.payment_outlined),
                    title: Text("Address "),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddressPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.favorite),
                    title: Text("Refer"),
                    trailing: Icon(Icons.chat_bubble_outlined, color: Colors.green),
                    onTap: () {
                      // Handle refer navigation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ComingSoonPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.headset_mic),
                    title: Text("Customer support 24x7"),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomerSupportPage()),
                      );
                    }, // Handle customer support navigation
                  ),
                  ListTile(
                    leading: Icon(Icons.file_copy),
                    title: Text("About us"),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Handle reports navigation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AboutUsPage()),
                      );
                    },
                  ),
                  // Sign-out button
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text("Sign out", style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginUser()), // Navigate to LoginPage
                            (Route<dynamic> route) => false, // This removes all the previous routes
                      );
                    },

                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

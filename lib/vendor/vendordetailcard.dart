import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';

class VendorDetailsCardPage extends StatefulWidget {
  final dynamic uid;

  const VendorDetailsCardPage({Key? key, required this.uid}) : super(key: key);

  @override
  _VendorDetailsCardPageState createState() => _VendorDetailsCardPageState();
}

class _VendorDetailsCardPageState extends State<VendorDetailsCardPage> {
  DocumentSnapshot<Map<String, dynamic>>? userDetails;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bnameController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    setState(() => isLoading = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            userDetails = snapshot;
            _nameController.text = snapshot.data()?['name'] ?? '';
            _emailController.text = snapshot.data()?['email'] ?? '';
            _phoneController.text = snapshot.data()?['phone'] ?? '';
            _bnameController.text = snapshot.data()?['bname'] ?? '';
            _panController.text = snapshot.data()?['pan'] ?? '';
          });
        } else {
          print('User not found');
        }
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || _imageFile == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${currentUser.uid}.jpg');
      await storageRef.putFile(_imageFile!);

      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentUser.uid)
          .update({'profilePicture': downloadUrl});

      fetchUserDetails();
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _showEditDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Name'),
                _buildTextField(_emailController, 'Email'),
                _buildTextField(_phoneController, 'Phone'),
                _buildTextField(_bnameController, 'Business Name'),
                _buildTextField(_panController, 'PAN Number'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUserDetails();
                Navigator.of(context).pop(); // Close dialog after saving
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('vendors').doc(currentUser.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'bname': _bnameController.text,
        'pan': _panController.text,
      });

      fetchUserDetails();
    } catch (e) {
      print('Error updating user details: $e');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: fetchUserDetails,
          child: isLoading
              ? _buildShimmerEffect()
              : userDetails == null
              ? Center(child: Text('No user details available'))
              : _buildUserDetails(),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: List.generate(
          5,
              (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: double.infinity,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 20),
            _buildInfoCard('Name', userDetails?.data()?['name']),
            _buildInfoCard('Email', userDetails?.data()?['email']),
            _buildInfoCard('Phone', userDetails?.data()?['phone']),
            _buildInfoCard('Business Name', userDetails?.data()?['bname']),
            _buildInfoCard('PAN Number', userDetails?.data()?['pan']),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Circle with a black border
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.black, // Border color
            child: CircleAvatar(
              radius: 58,
              backgroundColor: Colors.white, // Background color inside the avatar
              backgroundImage: userDetails?.data()?['profilePicture'] != null
                  ? NetworkImage(userDetails!['profilePicture'])
                  : const NetworkImage(
                'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/profile_pictures%2Fprofile001.png?alt=media&token=d45b08ab-bb2f-49aa-81d1-fc6376776cd3',
              ),
              onBackgroundImageError: (_, __) => const Icon(
                Icons.error,
                color: Colors.red,
                size: 40, // Error icon size
              ),
            ),
          ),

          // Image picker icon at the bottom-right
          Positioned(
            bottom: 0,
            right: 0,
              child: IconButton(
                icon: const Icon(Icons.add_a_photo, color: Colors.black),
                iconSize: 24,
                onPressed: _pickImage,
                tooltip: 'Change Profile Picture',
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildInfoCard(String label, String? value) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
          "$label: ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value ?? 'N/A'),
      ),
    );
  }
}

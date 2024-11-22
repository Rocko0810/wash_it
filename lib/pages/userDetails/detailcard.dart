import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package


class DetailsCardPage extends StatefulWidget {
  const DetailsCardPage({Key? key}) : super(key: key);

  @override
  _DetailsCardPageState createState() => _DetailsCardPageState();
}

class _DetailsCardPageState extends State<DetailsCardPage> {
  DocumentSnapshot<Map<String, dynamic>>? userDetails;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;

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
        DocumentSnapshot<
            Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            userDetails = snapshot;
            _nameController.text = userDetails?['name'] ?? '';
            _dobController.text = userDetails?['dob'] ?? '';
            _phoneController.text = userDetails?['phone'] ?? '';
            _selectedGender = userDetails?['gender'];
          });
        }
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
      setState(() {
      });
    }
  }


  Future<void> _updateUserDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('users')
          .doc(currentUser.uid)
          .update({
        'name': _nameController.text,
        'dob': _dobController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender,
      });

      fetchUserDetails();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating user details: $e');
    }
  }

  Future<void> _showEditDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Select your date of birth',
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _dobController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text("Select Gender"),
                    ),
                    DropdownMenuItem<String?>(
                      value: "Male",
                      child: Text("Male"),
                    ),
                    DropdownMenuItem<String?>(
                      value: "Female",
                      child: Text("Female"),
                    ),
                    DropdownMenuItem<String?>(
                      value: "Other",
                      child: Text("Other"),
                    ),
                  ],
                  decoration: InputDecoration(labelText: 'Gender'),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateUserDetails,
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: isLoading
          ? Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: List.generate(5, (index) => buildShimmerCard()),
        ),
      )
          : ListView(
        padding: EdgeInsets.all(16),
        children: [
          buildProfileImage(),
          SizedBox(height: 30),
          buildDetailCard('Email', FirebaseAuth.instance.currentUser?.email),
          buildDetailCard('Name', userDetails?['name']),
          buildDetailCard('Date of Birth', userDetails?['dob']),
          buildDetailCard('Phone Number', userDetails?['phone']),
          buildDetailCard('Gender', userDetails?['gender']),
        ],
      ),
    );
  }

  Widget buildShimmerCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Container(
          height: 20,
          width: 150,
          color: Colors.white,
        ),
        subtitle: Container(
          height: 14,
          width: 100,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildProfileImage() {
    String defaultImageUrl =
        'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/profile_pictures%2Fprofile001.png?alt=media&token=d45b08ab-bb2f-49aa-81d1-fc6376776cd3';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: userDetails?['profilePicture'] != null
                  ? NetworkImage(userDetails!['profilePicture'])
                  : NetworkImage(defaultImageUrl),
              backgroundColor: Colors.white,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_a_photo,
                  color: Colors.black,
                ),
                onPressed: _pickImage,
                tooltip: 'Change Profile Picture',
                iconSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailCard(String title, String? value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Set the title text to bold
          ),
        ),
        subtitle: Text(value ?? 'N/A'),
      ),
    );
  }
}

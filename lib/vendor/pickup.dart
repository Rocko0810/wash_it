import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PickupVerificationPage extends StatefulWidget {
  final String orderId;

  const PickupVerificationPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  _PickupVerificationPageState createState() => _PickupVerificationPageState();
}

class _PickupVerificationPageState extends State<PickupVerificationPage> {
  File? _pickedImage;
  bool _isUploading = false;
  Timestamp? _scheduledPickupTime;
  Timestamp? _verifiedPickupTime;
  bool _isPickupScheduled = false;
  DateTime? _selectedDateTime;

  final String vendorId = FirebaseAuth.instance.currentUser!.uid;
  late String userId; // Store User ID from the order data

  @override
  void initState() {
    super.initState();
    _fetchPickupDetails();
  }

  Future<void> _fetchPickupDetails() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.data() as Map<String, dynamic>?;

        if (orderData != null) {
          setState(() {
            userId = orderData['userId'];
            _scheduledPickupTime = orderData['pickupTime'];
            _verifiedPickupTime = orderData['verifiedPickupTime'];
            _isPickupScheduled = _scheduledPickupTime != null;
          });
        }
      } else {
        Fluttertoast.showToast(msg: 'Order not found.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching pickup details: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error picking image: $e');
    }
  }

  Future<void> _selectPickupTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _isPickupScheduled = true;
        });

        await _saveScheduledPickupTime();
        _fetchPickupDetails();
      }
    }
  }

  Future<void> _saveScheduledPickupTime() async {
    if (_selectedDateTime == null) return;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      Timestamp scheduledTime = Timestamp.fromDate(_selectedDateTime!);
      String formattedTime = _formatTimestamp(scheduledTime);

      // References for batch update
      DocumentReference vendorOrderRef = FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(widget.orderId);

      DocumentReference userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(widget.orderId);

      DocumentReference ordersReceivedRef = FirebaseFirestore.instance
          .collection('ordersReceived')
          .doc(widget.orderId);

      // Batch updates
      batch.update(vendorOrderRef, {
        'pickupTime': scheduledTime,
        'pickup': 'Scheduled at $formattedTime',
      });

      batch.update(userOrderRef, {
        'pickupTime': scheduledTime,
        'pickup': 'Scheduled at $formattedTime',
      });

      batch.update(ordersReceivedRef, {
        'pickupTime': scheduledTime,
        'pickup': 'Scheduled at $formattedTime',
      });

      await batch.commit();
      Fluttertoast.showToast(msg: 'Pickup time scheduled successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error scheduling pickup: $e');
    }
  }

  Future<void> _uploadImageAndVerifyPickup() async {
    if (_pickedImage == null) {
      Fluttertoast.showToast(msg: 'Please capture an image!');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = 'pickup_images/${widget.orderId}_${DateTime.now()}.jpg';
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child(fileName)
          .putFile(_pickedImage!);

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      Timestamp verifiedTime = Timestamp.now();
      String formattedTime = _formatTimestamp(verifiedTime);

      // References for batch update
      DocumentReference vendorOrderRef = FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(widget.orderId);

      DocumentReference userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(widget.orderId);

      DocumentReference ordersReceivedRef = FirebaseFirestore.instance
          .collection('ordersReceived')
          .doc(widget.orderId);

      // Batch updates
      batch.update(vendorOrderRef, {
        'verifiedPickupTime': verifiedTime,
        'pickupImage': imageUrl,
        'pickup': 'Picked Up at $formattedTime',
      });

      batch.update(userOrderRef, {
        'verifiedPickupTime': verifiedTime,
        'pickupImage': imageUrl,
        'pickup': 'Picked Up at $formattedTime',
      });

      batch.update(ordersReceivedRef, {
        'verifiedPickupTime': verifiedTime,
        'pickupImage': imageUrl,
        'pickup': 'Picked Up at $formattedTime',
      });

      await batch.commit();
      Fluttertoast.showToast(msg: 'Pickup verified successfully!');
      _fetchPickupDetails();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to verify pickup: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Soon';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Verification')),
      body: RefreshIndicator(
        onRefresh: _fetchPickupDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pickedImage != null
                  ? Image.file(
                _pickedImage!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : const Placeholder(
                fallbackHeight: 250,
                fallbackWidth: double.infinity,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: const Icon(Icons.camera),
                label: const Text('Capture Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectPickupTime,
                child: const Text('Select Pickup Time'),
              ),
              const SizedBox(height: 16),
              Text(
                'Scheduled Pickup: ${_formatTimestamp(_scheduledPickupTime)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Verified Pickup: ${_formatTimestamp(_verifiedPickupTime)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _verifiedPickupTime != null
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImageAndVerifyPickup,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Pickup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

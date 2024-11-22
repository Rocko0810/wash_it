import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DeliveryVerificationPage extends StatefulWidget {
  final String orderId;

  const DeliveryVerificationPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  _DeliveryVerificationPageState createState() =>
      _DeliveryVerificationPageState();
}

class _DeliveryVerificationPageState extends State<DeliveryVerificationPage> {
  File? _pickedImage;
  bool _isUploading = false;
  Timestamp? _scheduledDeliveryTime;
  Timestamp? _verifiedDeliveryTime;
  bool _isDeliveryScheduled = false;
  DateTime? _selectedDateTime;

  final String vendorId = FirebaseAuth.instance.currentUser!.uid;
  late String userId;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryDetails();
  }

  Future<void> _fetchDeliveryDetails() async {
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
            _scheduledDeliveryTime = orderData['deliveryTime'];
            _verifiedDeliveryTime = orderData['verifiedDeliveryTime'];
            _isDeliveryScheduled = _scheduledDeliveryTime != null;
          });
        }
      } else {
        Fluttertoast.showToast(msg: 'Order not found.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching delivery details: $e');
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

  Future<void> _selectDeliveryTime() async {
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
          _isDeliveryScheduled = true;
        });

        await _saveScheduledDeliveryTime();
        _fetchDeliveryDetails();
      }
    }
  }

  Future<void> _saveScheduledDeliveryTime() async {
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
        'deliveryTime': scheduledTime,
        'delivery': 'Scheduled at $formattedTime',
      });

      batch.update(userOrderRef, {
        'deliveryTime': scheduledTime,
        'delivery': 'Scheduled at $formattedTime',
      });

      batch.update(ordersReceivedRef, {
        'deliveryTime': scheduledTime,
        'delivery': 'Scheduled at $formattedTime',
      });

      await batch.commit();
      Fluttertoast.showToast(msg: 'Delivery time scheduled successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error scheduling delivery: $e');
    }
  }

  Future<void> _uploadImageAndVerifyDelivery() async {
    if (_pickedImage == null) {
      Fluttertoast.showToast(msg: 'Please capture an image!');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = 'delivery_images/${widget.orderId}_${DateTime.now()}.jpg';
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
        'verifiedDeliveryTime': verifiedTime,
        'deliveryImage': imageUrl,
        'delivery': 'Delivered at $formattedTime',
      });

      batch.update(userOrderRef, {
        'verifiedDeliveryTime': verifiedTime,
        'deliveryImage': imageUrl,
        'delivery': 'Delivered at $formattedTime',
      });

      batch.update(ordersReceivedRef, {
        'verifiedDeliveryTime': verifiedTime,
        'deliveryImage': imageUrl,
        'delivery': 'Delivered at $formattedTime',
      });

      await batch.commit();
      Fluttertoast.showToast(msg: 'Delivery verified successfully!');
      _fetchDeliveryDetails();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to verify delivery: $e');
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
      appBar: AppBar(title: const Text('Delivery Verification')),
      body: RefreshIndicator(
        onRefresh: _fetchDeliveryDetails,
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
                onPressed: _selectDeliveryTime,
                child: const Text('Select Delivery Time'),
              ),
              const SizedBox(height: 16),
              Text(
                'Scheduled Delivery: ${_formatTimestamp(_scheduledDeliveryTime)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Verified Delivery: ${_formatTimestamp(_verifiedDeliveryTime)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _verifiedDeliveryTime != null
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImageAndVerifyDelivery,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Delivery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

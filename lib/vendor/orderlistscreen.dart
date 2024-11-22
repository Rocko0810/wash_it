import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/vendor/pickup.dart';
import 'package:wash_it/widgets/shimmer.dart';
import 'package:wash_it/widgets/small_text.dart';
import 'package:wash_it/widgets/big_text.dart';
import '../../widgets/defaulttext.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'delivery.dart';

class VOrdersPages extends StatefulWidget {
  const VOrdersPages({super.key});

  @override
  _VOrdersPagesState createState() => _VOrdersPagesState();
}

class _VOrdersPagesState extends State<VOrdersPages> {
  String? _vendorName;
  static const double _platformFee = 2.00;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails(); // Fetch vendor name
  }

  Future<void> _fetchVendorDetails() async {
    try {
      String vendorId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .get();

      if (vendorSnapshot.exists) {
        setState(() {
          _vendorName = vendorSnapshot['name'] ?? 'Vendor';
        });
      } else {
        Fluttertoast.showToast(msg: 'Vendor not found.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching vendor details: $e');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy, HH:mm').format(dateTime);
  }

  String _getOrderStatus(Timestamp orderTimestamp, String originalStatus) {
    DateTime orderDate = orderTimestamp.toDate();
    DateTime currentTime = DateTime.now();
    Duration difference = currentTime.difference(orderDate);

    if (originalStatus == 'Cancelled') return 'Cancelled';
    if (difference.inMinutes <= 5) return 'Pending';
    return 'Confirmed';
  }

  Future<void> _updateOrderStatus(
      String orderId, String status, String collection) async {
    try {
      final docRef = FirebaseFirestore.instance.collection(collection).doc(orderId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        Fluttertoast.showToast(msg: 'Order not found.');
        return;
      }

      await docRef.update({
        'status': status,
        'statusUpdateTime': Timestamp.now(),
      });

      Fluttertoast.showToast(msg: 'Order status updated to $status');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String vendorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: BigText(text: 'Your Orders'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ShimmerLoading());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoOrdersWidget();
          }

          List<Map<String, dynamic>> orders = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          );
        },
      ),
      bottomNavigationBar: _vendorName != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Vendor: $_vendorName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildNoOrdersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No orders found.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    List<dynamic> items = order['cartItems'] ?? [];
    double totalAmount = order['totalAmount'] ?? 0.0;
    double gst = order['gst'] ?? 0.0;
    double deliveryCharge = order['deliveryCharge'] ?? 0.0;
    double discount = order['discount'] ?? 0.0;
    Timestamp orderTimestamp = order['orderDate'];
    String orderDate = _formatTimestamp(orderTimestamp);
    String orderId = order['orderId'] ?? 'Unknown ID';
    String paymentMode = order['paymentMode'] ?? 'Unknown Payment Mode';
    String originalStatus = order['status'] ?? 'Unknown Status';
    String orderStatus = _getOrderStatus(orderTimestamp, originalStatus);
    String pickup = order['pickup'] ?? 'Soon';
    String delivery = order['delivery'] ?? 'Soon';
    String address = order['address'] ?? 'Address not provided';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radius10),
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(text: 'Order ID: $orderId'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.clock, 'Order Date: $orderDate'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.infoCircle, 'Status: $orderStatus'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.mapPin, 'Pickup: $pickup'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.locationArrow, 'Delivery: $delivery'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.home, 'Address: $address'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.wallet, 'Payment: $paymentMode'),
              const Divider(),
              ...items.map((item) => _buildOrderItem(item)).toList(),
              _buildSummaryRow('GST', gst),
              _buildSummaryRow('Delivery Charge', deliveryCharge),
              _buildSummaryRow('Discount', discount),
              _buildSummaryRow('Platform Fee', _platformFee),
              const Divider(),
              _buildSummaryRow('Total', totalAmount),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PickupVerificationPage(orderId: orderId),
                          ),
                        );
                      },
                      child: const Text('Pickup Verification'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DeliveryVerificationPage(orderId: orderId),
                          ),
                        );
                      },
                      child: const Text('Item Delivered'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Expanded(child: SmallText(text: text)),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    String itemName = item['itemName'] ?? 'Unknown Item';
    int quantity = item['quantity'] ?? 0;
    double price = item['price'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$itemName x$quantity'),
          Text('₹${(price * quantity).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SmallText(text: label),
        SmallText(text: '₹${amount.toStringAsFixed(2)}'),
      ],
    );
  }
}

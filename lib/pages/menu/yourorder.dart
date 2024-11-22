import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/widgets/shimmer.dart';
import 'package:wash_it/widgets/small_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/big_text.dart';
import '../../widgets/defaulttext.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const double _platformFee = 2.00;

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy, HH:mm').format(dateTime);
  }

  String _getOrderStatus(Timestamp orderTimestamp, String originalStatus, String orderId) {
    DateTime orderDate = orderTimestamp.toDate();
    DateTime currentTime = DateTime.now();
    Duration difference = currentTime.difference(orderDate);

    String newStatus;
    if (originalStatus == 'Cancelled') {
      newStatus = 'Cancelled';
    } else if (difference.inMinutes <= 5) {
      newStatus = 'Pending';
    } else {
      newStatus = 'Confirmed';
    }

    if (newStatus != originalStatus) {
      _updateOrderStatus(orderId, newStatus); // Update Firestore if status changes.
    }

    return newStatus;
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      Fluttertoast.showToast(msg: 'Order status updated to $newStatus');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: BigText(text: 'Your Orders'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ShimmerLoading());
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
    String orderStatus = _getOrderStatus(orderTimestamp, originalStatus, orderId);
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
              SizedBox(height: Dimensions.Height10),
              _buildInfoRow(FontAwesomeIcons.clock, 'Order Date: $orderDate'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.infoCircle, 'Status: $orderStatus'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.indianRupee, 'Payment Mode: $paymentMode'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.mapMarkerAlt, 'Pickup: $pickup'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.truck, 'Delivery: $delivery'),
              SizedBox(height: Dimensions.Height10 / 3),
              _buildInfoRow(FontAwesomeIcons.home, 'Address: $address'),
              Divider(thickness: 3, color: Colors.grey.shade300),
              ...items.map((item) => _buildOrderItem(item)),
              Divider(),
              _buildSummaryRow('GST', gst),
              _buildSummaryRow('Delivery Charge', deliveryCharge),
              _buildSummaryRow('Discount', discount),
              _buildSummaryRow('Platform Fee', _platformFee),
              SizedBox(height: Dimensions.Height10),
              Divider(),
              _buildSummaryRow('Total', totalAmount),
              const SizedBox(height: 12),
              if (orderStatus == 'Pending')
                ElevatedButton(
                  onPressed: () => _showCancelConfirmationDialog(orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Order'),
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
    String dhobiName = item['dhobiName'] ?? 'Random';
    int quantity = item['quantity'] ?? 0;
    double price = item['price'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dhobiName),
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

  Future<void> _showCancelConfirmationDialog(String orderId) async {
    String cancelReason = '';
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView( // Make the dialog content scrollable
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to cancel this order?'),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) => cancelReason = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reason is required';
                      }
                      if (value.trim().length < 15) {
                        return 'Reason must be at least 15 characters long';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter the reason for cancellation',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2, // Limiting the height of the TextFormField
                    minLines: 1, // Ensure at least one line is visible
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _cancelOrder(orderId, cancelReason);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _cancelOrder(String orderId, String reason) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderSnapshot.exists) {
        Map<String, dynamic>? orderData = orderSnapshot.data() as Map<String, dynamic>?;
        String vendorId = orderData?['vendorId'] ?? '';

        WriteBatch batch = FirebaseFirestore.instance.batch();

        batch.set(
          FirebaseFirestore.instance.collection('cancelledOrders').doc(),
          {
            'orderId': orderId,
            'userId': userId,
            'vendorId': vendorId,
            'cancelReason': reason,
            'cancelDate': Timestamp.now(),
            'originalOrderData': orderData,
          },
        );

        batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId),
          {'status': 'Cancelled'},
        );

        if (vendorId.isNotEmpty) {
          batch.update(
            FirebaseFirestore.instance
                .collection('vendors')
                .doc(vendorId)
                .collection('orders')
                .doc(orderId),
            {'status': 'Cancelled'},
          );
        }

        await batch.commit();
        Fluttertoast.showToast(msg: 'Order cancelled successfully!');
      } else {
        Fluttertoast.showToast(msg: 'Order not found.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to cancel the order: $e');
    }
  }
}

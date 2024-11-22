import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InsightPage extends StatefulWidget {
  final String uid; // Vendor document ID

  const InsightPage({Key? key, required this.uid}) : super(key: key);

  @override
  _InsightPageState createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  bool isLoading = true; // Loading state
  List<Map<String, dynamic>> orders = []; // Store order data
  double totalEarnings = 0.0; // Store total earnings

  @override
  void initState() {
    super.initState();
    fetchOrderData(); // Fetch data on page load
  }

  // Fetch all orders from the vendor's orders sub-collection
  Future<void> fetchOrderData() async {
    setState(() => isLoading = true);

    try {
      // Query the vendor's orders collection to get all orders
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.uid) // Use passed vendor ID
          .collection('orders') // Access the 'orders' sub-collection
          .orderBy('orderDate', descending: true) // Sort by order date
          .get();

      // Extract order data into the list
      orders = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Calculate total earnings from 'totalAmount'
      totalEarnings = orders.fold(
        0.0,
            (sum, order) => sum + (order['totalAmount'] ?? 0.0),
      );
    } catch (e) {
      print('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders.')),
      );
    }

    setState(() => isLoading = false);
  }

  // Format Firestore timestamp
  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // Build individual order card
  Widget buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: order['deliveryImage'] != null
              ? NetworkImage(order['deliveryImage'])
              : null,
          backgroundColor: getStatusColor(order['status']),
          child: Icon(
            getStatusIcon(order['status']),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Total: ₹${order['totalAmount'].toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order['orderId']}'),
            Text('Date: ${formatDate(order['orderDate'])}'),
            Text('Payment Mode: ${order['paymentMode'] ?? 'N/A'}'),
            Text('Status: ${order['status']}'),
            if (order['platformFee'] != null)
              Text('Platform Fee: ₹${order['platformFee']}'),
            if (order['gst'] != null)
              Text('GST: ₹${order['gst']}'),
            if (order['discount'] != null && order['discount'] > 0)
              Text('Discount: ₹${order['discount']}'),
          ],
        ),
        trailing: Text(
          order['status'] ?? 'N/A',
          style: TextStyle(
            color: getStatusColor(order['status']),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Get color based on status
  Color getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get icon based on status
  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.hourglass_top;
      case 'Failed':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Pull-to-refresh logic
  Future<void> _onRefresh() async {
    await fetchOrderData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Insights'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : Column(
        children: [
          // Display total earnings
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Earnings:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Display order list
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('No orders found.'))
                : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return buildOrderCard(orders[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

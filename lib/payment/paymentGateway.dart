import 'dart:async'; // For handling timers
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../pages/orderplaced/orderplacedpage.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final String selectedAddress;
  final double platformFee;
  final double discountAmount;
  final double totalPrice;
  final Function onPaymentSuccess;
  final Function clearCart;
  final Function refreshCart;

  PaymentPage({
    required this.totalAmount,
    required this.totalPrice,
    required this.discountAmount,
    required this.platformFee,
    required this.selectedAddress,
    required this.onPaymentSuccess,
    required this.clearCart,
    required this.refreshCart,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  final Uuid _uuid = Uuid();
  String? _orderId;
  String? paymentMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _setLoading(true);
    Fluttertoast.showToast(msg: "Payment successful! Processing your order...");
    paymentMode = 'Online Payment';
    try {
      await saveOrderToFirestore(paymentId: response.paymentId);
      widget.clearCart();
      widget.refreshCart();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => OrderPlacedPage()));
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "Wallet selected: ${response.walletName}");
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_EAbLBzDkUXU6nZ',
      'amount': (widget.totalAmount * 100).toInt(),
      'name': 'Washit',
      'description': 'Payment for the product',
      'prefill': {
        'contact': '9876543210',
        'email': 'washit20sept@gmail.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error opening Razorpay: $e");
    }
  }

  void placeCodOrder() async {
    _setLoading(true);
    paymentMode = 'Cash on Delivery';
    try {
      await saveOrderToFirestore(isCod: true);
      Fluttertoast.showToast(msg: "Order placed successfully!");
      widget.clearCart();
      widget.refreshCart();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => OrderPlacedPage()));
    } catch (e) {
      Fluttertoast.showToast(msg: "Error placing order: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveOrderToFirestore(
      {String? paymentId, bool isCod = false}) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot cartDoc =
        await FirebaseFirestore.instance.collection('carts').doc(userId).get();

    if (!cartDoc.exists) {
      throw "Cart not found for the user.";
    }

    Map<String, dynamic>? cartData = cartDoc.data() as Map<String, dynamic>?;
    if (cartData == null || cartData.isEmpty) {
      throw "No items in the cart.";
    }

    List<Map<String, dynamic>> cartItems = cartData.entries.map((entry) {
      return {
        'itemName': entry.key,
        'dhobiName': entry.value['dhobiName'] ?? '',
        'dhobiId': entry.value['dhobiId'] ?? '',
        'price': entry.value['price'] ?? 0.0,
        'quantity': entry.value['quantity'] ?? 0,
      };
    }).toList();

    await _saveOrderData(userId, cartItems, isCod, paymentId);
    await cartDoc.reference.delete(); // Delete cart after success
  }

  Future<void> _saveOrderData(
      String userId,
      List<Map<String, dynamic>> cartItems,
      bool isCod,
      String? paymentId) async {
    double gst = widget.totalPrice * 0.08;
    double deliveryCharge =
        widget.totalPrice < 100 ? 40 : (widget.totalPrice <= 200 ? 20 : 0);
    String orderId = _generateOrderId();
    _orderId = orderId;

    Map<String, dynamic> orderData = {
      'userId': userId,
      'cartItems': cartItems,
      'totalAmount': widget.totalAmount,
      'address': widget.selectedAddress,
      'orderDate': Timestamp.now(),
      'status': 'Pending',
      'isCancelable': true,
      'paymentId': paymentId,
      'orderId': orderId,
      'paymentMode': paymentMode,
      'gst': gst,
      'deliveryCharge': deliveryCharge,
      'discount': widget.discountAmount,
      'platformFee': widget.platformFee,
    };

    await FirebaseFirestore.instance
        .collection('ordersReceived')
        .doc(orderId)
        .set(orderData);

    for (var item in cartItems) {
      String dhobiId = item['dhobiId'];
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(dhobiId)
          .collection('orders')
          .doc(orderId)
          .set(orderData);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .set(orderData);
  }

  String _generateOrderId() {
    return _uuid.v4();
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Delivery Address: ${widget.selectedAddress}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: openCheckout,
                    child: Text('Proceed to Payment'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: placeCodOrder,
                    child: Text('Cash on Delivery'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

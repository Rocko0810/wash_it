import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_manager.dart';
import 'cart_provider.dart'; // Import your CartProvider
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for saved addresses
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:wash_it/payment/paymentGateway.dart'; // Import for Payment Gateway
import 'dart:async'; // Import Timer

class CartsPage extends StatefulWidget {
  final CartManager cartManager = CartManager();// Your cart manager instance


  @override
  _CartsPageState createState() => _CartsPageState();
}

class _CartsPageState extends State<CartsPage> {
  final CartManager cartManager = CartManager(); // Define the cartManager instance
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddress = true;
  List<Map<String, dynamic>> _savedAddresses = [];
  Timer? _toastTimer;
  bool _hasShownMessage100 = false; // Flag for ₹100 message
  bool _hasShownMessage200 = false; // Flag for ₹200 message


  String? _selectedCoupon;
  String? _selectedCouponDescription;
  double discountAmount = 0.0;
  final List<Map<String, dynamic>> _availableCoupons = [
    {
      'code': 'WASHIT10',
      'discount': 10.0,
      'type': 'fixed',
      'description': '₹10 off on orders above ₹200'
    },
    {
      'code': 'WASHIT20',
      'discount': 20.0,
      'type': 'fixed',
      'description': '₹20 off on orders above ₹300'
    },
    {
      'code': 'WASHIT50',
      'discount': 50.0,
      'type': 'fixed',
      'description': '₹50 off on orders above ₹500'
    },
    {
      'code': 'WASHITGOLD10',
      'discount': 10.0,
      'type': 'percentage',
      'description': '10% off on orders above ₹1000'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchSavedAddresses(); // Fetch saved addresses
    _startToastTimer(); // Start toast timer
  }

  @override
  void dispose() {
    _toastTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }


  // Fetch saved addresses from Firestore
  Future<void> _fetchSavedAddresses() async {
    setState(() {
      _isLoadingAddress = true;
    });
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      setState(() {
        _savedAddresses = addressSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Set the first address as default if there are any addresses
        if (_savedAddresses.isNotEmpty) {
          _selectedAddress = _savedAddresses.first;  // Set the default address
        }

        _isLoadingAddress = false;
      });
    } catch (e) {
      print('Error fetching saved addresses: $e');
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  // Timer to show toast messages on the Cart Page only
  void _startToastTimer() {
    _toastTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (mounted) {  // Ensure the widget is still in the tree
        final cartTotal = context.read<CombinedDhobiCartProvider>().totalPrice;

        if (cartTotal > 0 && cartTotal < 100 && !_hasShownMessage100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Increase your cart value to ₹100 to reduce delivery charges!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          _hasShownMessage100 = true; // Set the flag to true after showing the message
        } else if (cartTotal >= 100 && cartTotal < 200 && !_hasShownMessage200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Increase your cart value to ₹200 to make delivery charges zero!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _hasShownMessage200 = true; // Set the flag to true after showing the message
        }
      }
    });
  }



  // Apply the selected coupon
  void _applyCoupon(double cartTotal) {
    if (_selectedCoupon != null) {
      final selectedCoupon = _availableCoupons.firstWhere(
              (coupon) => coupon['code'] == _selectedCoupon,
          orElse: () => {'discount': 0.0, 'type': 'fixed'}
      );

      // Apply fixed discounts
      if (selectedCoupon['type'] == 'fixed') {
        if (_selectedCoupon == 'WASHIT10' && cartTotal < 200) {
          setState(() {
            discountAmount = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '₹10 discount applies only for orders above ₹200.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (_selectedCoupon == 'WASHIT20' && cartTotal < 300) {
          setState(() {
            discountAmount = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '₹20 discount applies only for orders above ₹300.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (_selectedCoupon == 'WASHIT50' && cartTotal < 500) {
          setState(() {
            discountAmount = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '₹50 discount applies only for orders above ₹300.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            discountAmount = selectedCoupon['discount'];
          });
        }
      }

      // Apply percentage discount (10% off for orders above ₹1000)
      else if (selectedCoupon['type'] == 'percentage') {
        if (cartTotal > 1000) {
          setState(() {
            discountAmount = (selectedCoupon['discount'] / 100) * cartTotal;
          });
        } else {
          setState(() {
            discountAmount = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The 10% discount applies only for orders above ₹1000.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
// Method to calculate GST
  double calculateGST(double totalPrice) {
    return totalPrice * 0.08; // 8% GST
  }


  // Recalculate coupon when cart quantity changes
  void _onQuantityChanged() {
    double newTotalPrice = context.read<CombinedDhobiCartProvider>().totalPrice;
    _applyCoupon(newTotalPrice);
  }

  // Format address to string
  String _formatAddress(Map<String, dynamic> address) {
    return "${address['name']} ,${address['address']}, ${address['city']}, ${address['state']} - ${address['zip']} - ${address['phone']}";
  }
//calculate delivery charge function
  double calculateDeliveryCharge(double totalPrice) {
    double deliveryCharge = 40.00;

    if (totalPrice >= 200) {
      deliveryCharge = 0.0;  // No delivery charge for orders >= 200
    } else if (totalPrice >= 100) {
      deliveryCharge = deliveryCharge / 2;  // Half delivery charge for orders >= 100 but < 200
    }

    return deliveryCharge;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CombinedDhobiCartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),

      ),
      body: cart.cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/gif%2Fcart.gif?alt=media&token=de8bf321-dad9-4b0a-9d2d-339d817571e8',
            ),
            SizedBox(height: 20),
            const Text(
              'Cart is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchSavedAddresses,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cart items section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: List.generate(cart.cartItems.length, (index) {
                    String itemName = cart.cartItems.keys.elementAt(index);
                    var itemDetails = cart.cartItems[itemName]!;
                    int quantity = itemDetails['quantity'];
                    double price = itemDetails['price'];
                    String dhobiName = itemDetails['dhobiName'];
                    String dhobiId = itemDetails['dhobiId'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemName,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                  Text('Price: ₹$price',
                                      style: TextStyle(
                                          color: Colors.grey[700])),
                                  Text('Quantity: $quantity',
                                      style: TextStyle(
                                          color: Colors.grey[700])),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove, color: Colors.red),
                                  onPressed: () {
                                    cart.addItem(itemName, -1, price , dhobiName , dhobiId);
                                    _onQuantityChanged();
                                  },
                                ),
                                Text(quantity.toString(),
                                    style: TextStyle(fontSize: 18)),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.green),
                                  onPressed: () {
                                    cart.addItem(itemName, 1, price , dhobiName , dhobiId);
                                    _onQuantityChanged();
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                cart.removeItem(itemName);
                                _onQuantityChanged();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Address, Coupon, and Checkout Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Address Dropdown
                    if (_isLoadingAddress)
                      CircularProgressIndicator()
                    else if (_savedAddresses.isEmpty)
                      Text('No saved addresses. Please add one in your account settings.')
                    else
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedAddress,
                        hint: const Text('Select Delivery Address'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        ),
                        items: _savedAddresses.map((address) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: address,
                            child: Text(
                              _formatAddress(address),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (Map<String, dynamic>? newValue) {
                          setState(() {
                            _selectedAddress = newValue;
                          });
                        },
                        isExpanded: true,
                      ),

                    SizedBox(height: 16),

                    // Coupon Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCoupon,
                      hint: const Text('Apply Coupon'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.card_giftcard, color: Colors.blue),
                      ),
                      items: _availableCoupons.map((coupon) {
                        return DropdownMenuItem<String>(
                          value: coupon['code'],
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coupon['code'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  coupon['description'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoupon = newValue;
                          _applyCoupon(cart.totalPrice);
                        });
                      },
                      isExpanded: true,
                    ),

                    SizedBox(height: 8),

                    // Display coupon description below the dropdown
                    if (_selectedCouponDescription != null)
                      Text(
                        _selectedCouponDescription!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                    SizedBox(height: 16),

                    // Checkout Summary
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total:', style: TextStyle(fontSize: 18)),
                                Text(
                                  '₹${cart.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (discountAmount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:', style: TextStyle(fontSize: 18)),
                                  Text(
                                    '- ₹${discountAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('GST (8%):', style: TextStyle(fontSize: 18)),
                                Text(
                                  '₹${(calculateGST(cart.totalPrice)).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, color: Colors.black),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delivery Charge:', style: TextStyle(fontSize: 18)),
                                Text(
                                  '₹${calculateDeliveryCharge(cart.totalPrice).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 18, color: Colors.black),
                                ),
                              ],
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Platform Fee:', style: TextStyle(fontSize: 18)),
                                Text('₹2.00', style: TextStyle(fontSize: 18, color: Colors.black)),
                              ],
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable:',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${(cart.totalPrice + calculateDeliveryCharge(cart.totalPrice) + calculateGST(cart.totalPrice) + 2 - discountAmount).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Checkout Button
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedAddress == null) {
                          // Show a warning message if no address is selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a delivery address.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          // Proceed to the payment gateway if an address is selected
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                totalAmount: (cart.totalPrice +
                                    calculateDeliveryCharge(cart.totalPrice) +
                                    calculateGST(cart.totalPrice) +
                                    2 -
                                    discountAmount),
                                selectedAddress: _formatAddress(_selectedAddress!),
                                onPaymentSuccess: () {
                                  cart.clearCart(); // Clear the cart here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order placed successfully!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                clearCart: cartManager.clearCart,
                                refreshCart: cartManager.refreshCart, totalPrice: cart.totalPrice, discountAmount: discountAmount, platformFee: 2,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text('Proceed to Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}


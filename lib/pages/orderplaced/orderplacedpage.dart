import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Cart/cart_provider.dart';

class OrderPlacedPage extends StatelessWidget {
  OrderPlacedPage();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // This block runs when the user tries to go back using the device's back button
        Provider.of<CombinedDhobiCartProvider>(context, listen: false).clearCart();

        // Return true to allow the page to be popped (i.e., navigate back)
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Placed'),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your order has been placed successfully!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Clear cart when the "Back to Home" button is pressed
                  Provider.of<CombinedDhobiCartProvider>(context, listen: false).clearCart();

                  // Navigate back to the first screen (home)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

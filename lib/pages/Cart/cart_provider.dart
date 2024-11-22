import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CombinedDhobiCartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  // Cart map: itemName -> { 'quantity': int, 'price': double, 'dhobiId': String }
  Map<String, Map<String, dynamic>> _cartItems = {};
  String? _currentDhobiId;

  CombinedDhobiCartProvider({required this.userId}) {
    _loadCartItems();
  }

  // Get a copy of the cart items
  Map<String, Map<String, dynamic>> get cartItems => {..._cartItems};

  // Get current vendor ID
  String? get currentDhobiId => _currentDhobiId;

  // Load cart items from Firestore
  Future<void> _loadCartItems() async {
    try {
      final doc = await _firestore.collection('carts').doc(userId).get();
      if (doc.exists) {
        _cartItems = Map<String, Map<String, dynamic>>.from(doc.data()!);
        _currentDhobiId = _getDhobiIdFromCart();
      }
    } catch (e) {
      print("Error loading cart items: $e");
    } finally {
      notifyListeners();
    }
  }

  // Save cart items to Firestore
  Future<void> _saveCartItems() async {
    try {
      await _firestore.collection('carts').doc(userId).set(_cartItems);
    } catch (e) {
      print("Error saving cart items: $e");
    }
  }

  // Add or update an item in the cart, including increment and decrement
  void addItem(String itemName, int quantity, double price, String dhobiName, String dhobiId) {
    if (quantity == 0) return;

    // Check if the item belongs to a different vendor
    if (_currentDhobiId != null && _currentDhobiId != dhobiId) {
      clearCart();
    }

    // Set the new vendor ID
    _currentDhobiId = dhobiId;

    // Update or add item
    if (_cartItems.containsKey(itemName)) {
      int updatedQuantity = (_cartItems[itemName]!['quantity'] as int) + quantity;

      if (updatedQuantity > 0) {
        // Update to the new quantity
        _cartItems[itemName]!['quantity'] = updatedQuantity;
      } else {
        // Remove the item if quantity reaches 0
        _cartItems.remove(itemName);
        if (_cartItems.isEmpty) _currentDhobiId = null;
      }
    } else if (quantity > 0) {
      // Add a new item if quantity is positive
      _cartItems[itemName] = {
        'quantity': quantity,
        'price': price,
        'dhobiName': dhobiName,
        'dhobiId': dhobiId,
      };
    }

    _saveCartItems();
    notifyListeners();
  }

  // Remove an item from the cart
  void removeItem(String itemName) {
    if (_cartItems.containsKey(itemName)) {
      _cartItems.remove(itemName);

      if (_cartItems.isEmpty) _currentDhobiId = null;

      _saveCartItems();
      notifyListeners();
    }
  }

  // Update the quantity of an item in the cart
  void updateItemQuantity(String itemName, int quantity) {
    if (_cartItems.containsKey(itemName)) {
      if (quantity > 0) {
        _cartItems[itemName]!['quantity'] = quantity;
      } else {
        removeItem(itemName);
      }

      _saveCartItems();
      notifyListeners();
    }
  }

  // Get the total price of all items in the cart
  double get totalPrice {
    return _cartItems.entries.fold(0.0, (total, entry) {
      final quantity = entry.value['quantity'] as int;
      final price = entry.value['price'] as double;
      return total + (quantity * price);
    });
  }

  // Get the total number of items in the cart
  int totalItems() {
    return _cartItems.values.fold(0, (sum, item) {
      return sum + (item['quantity'] as int);
    });
  }

  // Clear the cart
  void clearCart() {
    _cartItems.clear();
    _currentDhobiId = null;
    _saveCartItems();
    notifyListeners();
  }

  // Check if the cart is empty
  bool get isCartEmpty => _cartItems.isEmpty;

  // Place an order and clear the cart afterward
  Future<void> placeOrder() async {
    if (_cartItems.isEmpty) return;

    try {
      await _firestore.collection('orders').add({
        'userId': userId,
        'items': _cartItems,
        'totalPrice': totalPrice,
        'orderDate': DateTime.now(),
      });

      clearCart();
    } catch (error) {
      print("Failed to place order: $error");
      throw Exception("Failed to place order: $error");
    }
  }

  // Helper: Get the vendor ID from the cart
  String? _getDhobiIdFromCart() {
    if (_cartItems.isNotEmpty) {
      return _cartItems.values.first['dhobiId'] as String?;
    }
    return null;
  }
}

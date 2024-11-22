import 'package:wash_it/pages/Cart/cart.dart';


class CartManager {
  List<CartsPage> _cartsPage = [];

  // Function to clear the cart
  void clearCart() {
    _cartsPage.clear();
    // You might want to save this change to Firestore or shared preferences here
  }

  // Function to refresh the cart items (e.g., fetch from Firestore)
  void refreshCart() {
    // Fetch the updated cart items and set the state in your cart page
    // For example, you might call a Firestore fetch function
  }

  // Function to get current cart items (optional)
  List<CartsPage> get cartItems => _cartsPage;
}

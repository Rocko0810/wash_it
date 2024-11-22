import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:persistent_bottom_nav_bar_plus/persistent_bottom_nav_bar_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../Dimensions/dimensions.dart';
import '../../no_internet.dart';
import '../../widgets/big_text.dart';
import '../Cart/cart.dart';
import '../menu/menu.dart';
import '../menu/yourorder.dart';
import 'homepage.dart';
import '../Cart/cart_provider.dart';

class MainWashIt extends StatefulWidget {
  const MainWashIt({Key? key}) : super(key: key);

  @override
  _MainWashItState createState() => _MainWashItState();
}

class _MainWashItState extends State<MainWashIt> {
  late PersistentTabController _controller;
  bool isLoading = true;
  String? _authorizationStatus;
  late StreamSubscription _internetConnectionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _requestNotificationPermission();
    _internetConnectionStreamSubscription =
        InternetConnection().onStatusChange.listen(
              (event) {
            if (event == InternetStatus.disconnected) {
              _navigateToNoInternetPage();
            }
          },
          onError: (error) {
            debugPrint("Internet connection stream error: $error");
          },
        );

    // Simulate a loading delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription.cancel();
    super.dispose();
  }

  void _navigateToNoInternetPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const NoConnectionPage(),
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    setState(() {
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          _authorizationStatus = "User granted permission";
          break;
        case AuthorizationStatus.provisional:
          _authorizationStatus = "User granted provisional permission";
          break;
        case AuthorizationStatus.denied:
          _authorizationStatus = "User denied permission";
          break;
        case AuthorizationStatus.notDetermined:
        default:
          _authorizationStatus = "Notification permission not determined";
          break;
      }
    });
  }

  // Define Home Page with AppBar
  Widget _buildHomeScreen() {
    return Scaffold(
      body: Column(
        children: [
          // Header of the page
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: Dimensions.radius10,
                  offset: Offset(5, 5),
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.only(
                  top: Dimensions.Height45, bottom: Dimensions.Width15),
              padding: EdgeInsets.only(
                  left: Dimensions.Width20, right: Dimensions.Width20),
              child: Row(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/gif%2FAnimation.gif?alt=media&token=2b2b6071-731d-4945-bbaa-87bc34897ae3',
                          ),
                          BigText(
                            text: "WashIt",
                            color: Colors.green,
                            size: Dimensions.font20 * 1.5,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(), // Add a spacer to push the cart icon to the right
                  Consumer<CombinedDhobiCartProvider>(
                    builder: (context, cartProvider, child) {
                      return Stack(
                        children: [
                          Padding(padding: EdgeInsets.only(right: Dimensions.Width40)),
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CartsPage()),
                              );
                            },
                          ),
                          if (cartProvider.totalItems() > 0) // Show badge only if items > 0
                            Positioned(
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '${cartProvider.totalItems()}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Body content with shimmer effect or actual content
          Expanded(
            child: isLoading
                ? _buildShimmerEffect() // Show shimmer if loading
                : SingleChildScrollView(
              child: Column(
                children: [
                  SegmentPage(), // Replace with actual content
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // List of screens
  List<Widget> _buildScreens() {
    return [
      _buildHomeScreen(),    // Home Screen with AppBar
      UserMenuPage(),        // User Menu
      OrdersPage(),          // Orders Page
    ];
  }

  // Bottom Navigation Items
  List<PersistentBottomNavBarItem> _navBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: Colors.green,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "Me",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.receipt_long_sharp),
        title: "Your Orders",
        activeColorPrimary: Colors.red,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }


@override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Show loading shimmer effect
      return Scaffold(
        body: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListView.builder(
              itemCount: 8, // Number of shimmer items to display
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  height: 100, // Height of shimmer item
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radius15),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Persistent Bottom Navigation Bar
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardShows: true,
      decoration: const NavBarDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.3),
        ),
      ),
      itemAnimationProperties: const ItemAnimationProperties(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        animateTabTransition: true,
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style1, // Style 1 applied here
    );
  }
}
// Function to build the shimmer effect
Widget _buildShimmerEffect() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      itemCount: 10, // Number of shimmer items to display
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          height: 100, // Height of shimmer item
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radius15),
          ),
        );
      },
    ),
  );
}

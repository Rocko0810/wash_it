import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:wash_it/login%20page/login.dart';
import 'package:wash_it/splashscreen/splash_screen.dart';

class NoConnectionPage extends StatefulWidget {
  const NoConnectionPage({super.key});

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends State<NoConnectionPage> {
  late StreamSubscription _internetConnectionStreamSubscription;
  bool isConnectedToInternet = false;

  @override
  void initState() {
    super.initState();
    // Listen to connection status changes
    _internetConnectionStreamSubscription =
        InternetConnection().onStatusChange.listen(
              (event) {
            if (event == InternetStatus.connected) {
              _navigateToPreviousOrLoginPage();
            }
            setState(() {
              isConnectedToInternet = event == InternetStatus.connected;
            });
          },
          onError: (error) {
            debugPrint("Internet connection stream error: $error");
          },
        );
    _checkConnection(); // Check connection on page load
  }

  // This method checks internet connectivity when the user refreshes the page
  Future<void> _checkConnection() async {
    bool isConnected = await _checkInternetConnection();
    setState(() {
      isConnectedToInternet = isConnected;
    });
    if (isConnected) {
      _navigateToPreviousOrLoginPage();
    }
  }

  // Checks internet connection by attempting to resolve google.com
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _navigateToPreviousOrLoginPage() {
    // Navigate back to the previous page or to LoginPage if no previous page exists
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Pop the current page
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SplashScreen(),
        ),
      );
    }
  }


  @override
  void dispose() {
    _internetConnectionStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("No Internet"),
      ),
      body: RefreshIndicator(
        onRefresh: _checkConnection, // Triggers the connection check
        child: SingleChildScrollView(
          // Wrap in a scrollable widget
          child: Container(
            height: MediaQuery.of(context).size.height, // Make it fill the screen
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/image/cutie.gif", height: 100), // GIF for no internet

                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 30.0, vertical: 20.0), // Adds margin around the Text
                    child: const Text(
                      "Oops! It seems you're not connected to the internet.",
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Pull down to refresh."),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

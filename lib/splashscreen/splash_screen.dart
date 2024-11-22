import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/login%20page/login.dart';
import 'package:wash_it/pages/home/main_wash_it_page.dart';

import '../no_internet.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.1;
  bool _showLoadingIndicator = false;
  Timer? _loadingIndicatorTimer;
  late StreamSubscription _internetConnectionStreamSubscription;

  void _navigateToNoInternetPage() {
    // Navigate to the NoConnectionPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const NoConnectionPage(),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _startAnimation();
    _startLoadingIndicatorDelay();
    _checkUserStatusAfterDelay();
    // Start listening to the internet connection status
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
  }

  void _startLoadingIndicatorDelay() {
    _loadingIndicatorTimer = Timer(Duration(seconds: 4), () {
      setState(() {
        _showLoadingIndicator = true;
      });
    });
  }

  Future<void> _checkUserStatusAfterDelay() async {
    await Future.delayed(Duration(seconds: 3));
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user == null || !user.emailVerified) {
        _navigateToLogin();
      } else {
        _navigateToMainPage();
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  void _navigateToLogin() {
    _loadingIndicatorTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginUser()),
    );
  }

  void _navigateToMainPage() {
    _loadingIndicatorTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainWashIt()),
    );
  }

  void _startAnimation() {
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription.cancel();
    _loadingIndicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 2),
              child: Image.asset("assets/image/washit.png"),
            ),
            if (_showLoadingIndicator)
              Positioned(
                bottom: Dimensions.Height20 * 3,
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:wash_it/pages/Cart/cart_provider.dart';
import 'package:wash_it/splashscreen/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Safely get the current user ID if the user is signed in
  final currentUser = FirebaseAuth.instance.currentUser;
  final userId = currentUser?.uid ?? ''; // Assign empty string if user is null

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CombinedDhobiCartProvider(userId: userId), // Pass userId to the provider
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WashIt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}


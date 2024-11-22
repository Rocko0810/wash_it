// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCZfsVSHxQEiemGrp03_Mq9J5zKuZT7SI',
    appId: '1:425045673446:android:ac63703759daddab31c227',
    messagingSenderId: '425045673446',
    projectId: 'washit-25714',
    storageBucket: 'washit-25714.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHtFVBhkY59loeAfJr6vZZfNIFnTzYcTY',
    appId: '1:425045673446:web:815da1938cfe388e31c227',
    messagingSenderId: '425045673446',
    projectId: 'washit-25714',
    authDomain: 'washit-25714.firebaseapp.com',
    storageBucket: 'washit-25714.appspot.com',
    measurementId: 'G-RCV81Q1DFD',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCse4WmiNkHhoKI9DuMgNzyOQoquC3bpTE',
    appId: '1:425045673446:ios:5d215f7ce6bd518231c227',
    messagingSenderId: '425045673446',
    projectId: 'washit-25714',
    storageBucket: 'washit-25714.appspot.com',
    iosBundleId: 'com.example.washIt',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCse4WmiNkHhoKI9DuMgNzyOQoquC3bpTE',
    appId: '1:425045673446:ios:5d215f7ce6bd518231c227',
    messagingSenderId: '425045673446',
    projectId: 'washit-25714',
    storageBucket: 'washit-25714.appspot.com',
    iosBundleId: 'com.example.washIt',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAHtFVBhkY59loeAfJr6vZZfNIFnTzYcTY',
    appId: '1:425045673446:web:6897fbb2ac89b1f931c227',
    messagingSenderId: '425045673446',
    projectId: 'washit-25714',
    authDomain: 'washit-25714.firebaseapp.com',
    storageBucket: 'washit-25714.appspot.com',
    measurementId: 'G-HPC0FDBEDD',
  );

}
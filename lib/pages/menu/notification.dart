import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<RemoteMessage> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

    // Listen for messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received a message: ${message.notification?.title}");
      _storeNotificationInFirestore(message);
      setState(() {
        _notifications.add(message);
      });
    });

    // Handle notification clicks when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked!");
      _storeNotificationInFirestore(message);
      setState(() {
        _notifications.add(message);
      });
    });
  }

  // Initialize Firebase and request notification permission
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();

    String? token = await messaging.getToken();
    print("FCM Token: $token");

    // Save token to Firestore
    await _saveTokenToFirestore('user123', 'users', token);

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Notification permission status: ${settings.authorizationStatus}");
  }

  // Save FCM Token to Firestore
  Future<void> _saveTokenToFirestore(
      String userId, String userType, String? token) async {
    if (token != null) {
      await FirebaseFirestore.instance
          .collection(userType) // 'users' or 'vendors'
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
      print("FCM Token saved for $userId");
    }
  }

  // Store notification in Firestore
  Future<void> _storeNotificationInFirestore(RemoteMessage message) async {
    final notificationData = {
      'title': message.notification?.title ?? 'No Title',
      'body': message.notification?.body ?? 'No Body',
      'timestamp': Timestamp.now(),
      'data': message.data,
    };

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);
      print("Notification stored in Firestore");
    } catch (e) {
      print("Error storing notification: $e");
    }
  }

  // Retrieve FCM token from Firestore
  Future<String?> _getFcmToken(String userId, String userType) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(userType)
          .doc(userId)
          .get();
      return snapshot['fcmToken'] as String?;
    } catch (e) {
      print("Error fetching FCM token: $e");
      return null;
    }
  }

  // Send notification using FCM API
  Future<void> _sendFCMNotification(
      String token, String title, String body) async {
    const String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace with your FCM server key
    final String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
        }),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // Send order notification to user or vendor
  Future<void> sendOrderNotification(
      String orderId, String eventType, String userId, String userType) async {
    String? token = await _getFcmToken(userId, userType);

    if (token == null) {
      print("FCM token not found for $userId");
      return;
    }

    String title;
    String body;

    switch (eventType) {
      case 'placed':
        title = 'Order Placed';
        body = 'Your order #$orderId has been placed.';
        break;
      case 'pickupScheduled':
        title = 'Pickup Scheduled';
        body = 'Your order #$orderId is scheduled for pickup.';
        break;
      case 'pickedUp':
        title = 'Order Picked Up';
        body = 'Your order #$orderId has been picked up.';
        break;
      case 'deliveryScheduled':
        title = 'Delivery Scheduled';
        body = 'Your order #$orderId is scheduled for delivery.';
        break;
      default:
        print("Unknown event type");
        return;
    }

    await _sendFCMNotification(token, title, body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: _notifications.isEmpty
          ? Center(child: Text('No Notifications'))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            leading: Icon(Icons.notifications),
            title: Text(notification.notification?.title ?? 'No Title'),
            subtitle: Text(notification.notification?.body ?? 'No Body'),
            onTap: () {
              print("Notification clicked: ${notification.data}");
            },
          );
        },
      ),
    );
  }
}

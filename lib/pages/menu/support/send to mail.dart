import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SendEmailScreen extends StatelessWidget {
  // Function to launch the email client with pre-filled data
  void _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'washitofficial20sept@gmail.com',
      query: 'subject=${Uri.encodeComponent('Help Request')}&body=${Uri.encodeComponent('Hello, I need some assistance...')}',
    );

    // Attempt to launch email with external application mode
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication, // Force opening external app
      );
    } else {
      print('Could not launch email client');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No email app found!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Me Mail') , backgroundColor: Colors.white,),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add the image from assets
            Image.asset(
              'assets/image/washit.png', // Replace with your image path
              height: 400, // Adjust height as needed
              width: 400,  // Adjust width as needed
            ),
            SizedBox(height: 20), // Space between the image and button
            ElevatedButton(
              onPressed: () => _sendEmail(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Send me an email' , style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

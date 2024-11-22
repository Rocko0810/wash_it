import 'package:flutter/material.dart';
import 'package:wash_it/pages/menu/support/callus.dart';
import 'package:wash_it/pages/menu/support/send%20to%20mail.dart';

import 'customerticket.dart';
import 'cummunitychat.dart';
import 'faq_page.dart';

class CustomerSupportPage extends StatefulWidget {
  @override
  _CustomerSupportPageState createState() => _CustomerSupportPageState();
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Support'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
         // _buildSupportCategories(),
          SizedBox(height: 20),
          _buildFAQSection(context),
          SizedBox(height: 20),
          _buildContactOptions(),
        ],
      ),
    );
  }

 /* Widget _buildSupportCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Support Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildCategoryTile(Icons.payment, 'Payments'),
            _buildCategoryTile(Icons.local_shipping, 'Shipping'),
            _buildCategoryTile(Icons.person, 'Account'),
            _buildCategoryTile(Icons.help_outline, 'General Help'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // Implement navigation to respective category details page
        print('$title category tapped');
      },
      child: Chip(
        avatar: Icon(icon, color: Colors.white),
        label: Text(title),
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
    );
  }*/

  // Main FAQ section
  Widget _buildFAQSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildFAQTile(context, 'How can I get my order status?', 'You can check your order status in the "My Orders" section.'),
        _buildFAQTile(context, 'How do I change my payment method?', 'To change your payment method, go to the payment settings page.'),
        _buildFAQTile(context, 'What is the cancellation policy?', 'Cancellations can be made within 5 hours of placing the order.'),
        _buildFAQTile(context, 'How can I reset my password?', 'You can reset your password by going to the account settings.'),
      ],
    );
  }

// FAQ tile builder with navigation to answer page
  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    return ListTile(
      title: Text(question),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.red),
      onTap: () {
        // Navigate to FAQAnswerPage with the question and answer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FAQAnswerPage(question: question, answer: answer),
          ),
        );
      },
    );
  }

  Widget _buildContactOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Need More Help?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.chat_bubble_outline,color: Colors.red,),
          title: Text('Chat with Support'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatScreen()),
            );
            // Implement live chat or messaging feature
            print('Chat tapped');
          },
        ),
        ListTile(
          leading: Icon(Icons.email_outlined , color: Colors.green,),
          title: Text('Send an Email'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SendEmailScreen()),
            );
            // Implement live chat or messaging feature
            print('Email tapped');
          },
        ),
        ListTile(
          leading: Icon(Icons.phone , color: Colors.green,),
          title: Text('Request Call Support'),
          onTap: () {
            // Implement call function
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RequestCallPage()),
            );
            print('Call tapped');
          },
        ),
        ListTile(
          leading: Icon(Icons.article_outlined , color: Colors.green,),
          title: Text('Submit a Help Ticket'),
          onTap: () {
            // Implement help ticket submission
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SubmitHelpTicketPage()),
            );
          },
        ),
      ],
    );
  }
}

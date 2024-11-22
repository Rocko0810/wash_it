import 'package:flutter/material.dart';
import 'package:wash_it/Dimensions/dimensions.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us' ,),
        backgroundColor: Colors.white,
        centerTitle: true,  // Centers the title
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Image
            Stack(
              children: [
                Container(
                  height: Dimensions.Height250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/image/washit.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: Dimensions.Height250,
                  color: Colors.black.withOpacity(0.4),
                ),
                Positioned(
                  bottom: Dimensions.Height20,
                  left: Dimensions.Width15,
                  child: const Text(
                    'Welcome to WashIt Laundry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Padding and Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Our Story Section
                  const Text(
                    'Our Story',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10),
                  const Text(
                    'WashIt Laundry was born out of a simple idea: making laundry easier and more convenient for everyone. Our goal is to provide top-notch laundry services with quick pick-ups, eco-friendly cleaning, and on-time delivery, ensuring that our customers get the best service every time.',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  SizedBox(height: Dimensions.Height20),

                  // Mission Section
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10),
                  const Text(
                    'At WashIt, our mission is to make laundry day effortless for our customers. We use state-of-the-art equipment, gentle detergents, and provide excellent customer care, ensuring that your clothes are clean, fresh, and handled with care.',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  SizedBox(height: Dimensions.Height20),

                  // Vision Section
                  const Text(
                    'Our Vision',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10),
                  const Text(
                    'Our vision is to be a leader in the laundry service industry by offering innovative and efficient solutions. We aim to expand our services, enhance customer satisfaction, and promote sustainability by reducing water and energy consumption in every wash.',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  SizedBox(height: Dimensions.Height20),

                  // Our Values Section
                  const Text(
                    'Our Values',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10),
                  _buildValueTile('Reliability', 'We always deliver on time and provide consistent, high-quality laundry services.'),
                  _buildValueTile('Sustainability', 'We are committed to eco-friendly practices that help reduce our environmental impact.'),
                  _buildValueTile('Customer Satisfaction', 'Our customers are our top priority, and we strive to exceed their expectations with every wash.'),

                  // Meet the Team Section
                  SizedBox(height: Dimensions.Height30),
                  const Text(
                    'Meet the Team',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: Dimensions.Height10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeamMemberWidget('assets/image/washit.png', 'Aditya Ray & \nSuryance Raj', 'Founder & CEO'),
                        SizedBox(width: Dimensions.Width10), // Adjust spacing between members
                        _buildTeamMemberWidget('assets/image/washit.png', 'Suryance Raj', 'Operations Manager'),
                        SizedBox(width: Dimensions.Width10),
                        _buildTeamMemberWidget('assets/image/washit.png', 'Aditya Ray', 'Customer Relations'),
                      ],
                    ),
                  ),


                  SizedBox(height: Dimensions.Height30),

                  // Call to Action
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Add action for contact or service
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.Width20, vertical: Dimensions.Height30/3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radius30),
                        ),
                      ),
                      child: Text(
                        'Get in Touch',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create values tiles
  Widget _buildValueTile(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: Dimensions.Width10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(description, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create team member tiles
  Widget _buildTeamMemberWidget(String imagePath, String name, String role) {
    return SizedBox(
      width: 120, // Consistent width for each team member
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(imagePath),
          ),
          SizedBox(height: Dimensions.Height10),
          Text(
            name,
            textAlign: TextAlign.center, // Center-align the name
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

}

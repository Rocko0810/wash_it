import 'package:flutter/material.dart';
import 'package:wash_it/pages/home/premiun.dart';

import '../menu/support/comming soon.dart';
import 'average.dart';

class SegmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Premium Segment
          SegmentContainer(
            title: "Premium Segment",
            description: "Exclusive services for our customers.",    //elite customers
            gradientColors: [Colors.purpleAccent, Colors.deepPurple],
            icon: Icons.star,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PremiumDhobiPage()),
              );

            },
          ),
          const SizedBox(height: 20),

          // Average Segment
          SegmentContainer(
            title: "Bulk Orders",
            description: "Affordable services for daily needs.",
            gradientColors: [Colors.orangeAccent, Colors.redAccent],
            icon: Icons.thumb_up,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AverageDhobiPage()),
              );

            },
          ),
          const SizedBox(height: 20),

          // Seasonal Offers
          SegmentContainer(
            title: "Seasonal Offers",
            description: "Limited-time discounts for festive seasons!",
            gradientColors: [Colors.blueAccent, Colors.cyan],
            icon: Icons.local_offer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ComingSoonPage()),
              );

            },
          ),
          const SizedBox(height: 20),

          // New Arrivals
          SegmentContainer(
            title: "New Arrivals",
            description: "Check out the latest additions to our services.",
            gradientColors: [Colors.greenAccent, Colors.lightGreen],
            icon: Icons.fiber_new,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ComingSoonPage()),
              );
            },
          ),
          const SizedBox(height: 20),

          // Exclusive Discounts
          SegmentContainer(
            title: "Exclusive Discounts",
            description: "Grab your discount before it’s gone!",
            gradientColors: [Colors.pinkAccent, Colors.redAccent],
            icon: Icons.discount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ComingSoonPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SegmentContainer extends StatelessWidget {
  final String title;
  final String description;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  const SegmentContainer({
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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
}

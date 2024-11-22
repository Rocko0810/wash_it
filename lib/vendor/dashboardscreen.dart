import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wash_it/vendor/productlistscreen.dart';
import 'package:wash_it/vendor/support.dart';
import 'package:wash_it/vendor/vendordetailcard.dart';
import 'Insights.dart';
import 'orderlistscreen.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;
  final String orderId;

  DashboardScreen({required this.uid, required this.orderId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<double> weeklyOrders = List.filled(7, 0);
  List<String> weekDates = [];
  bool isLoading = true;
  DateTime selectedStartDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateWeekDates(selectedStartDate);
    fetchWeeklyOrderData();
  }

  // Method to generate the week dates from a given start date
  void _generateWeekDates(DateTime startDate) {
    DateFormat dateFormat = DateFormat('MM/dd');
    setState(() {
      weekDates = List.generate(7, (index) {
        DateTime date = startDate.add(Duration(days: index));
        return dateFormat.format(date);
      });
      print("Generated weekDates: $weekDates");
    });
  }

  Future<void> fetchWeeklyOrderData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Calculate the end of the week from the selected start date
      DateTime endOfWeek = selectedStartDate.add(Duration(days: 6));

      // Fetch orders from the vendor's sub-collection with the pickupTime field
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors') // Access the 'vendors' collection
          .doc(widget.uid) // Access the specific vendor document by UID
          .collection('orders') // Access the 'orders' sub-collection
          .where('pickupTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedStartDate))
          .where('pickupTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      List<double> ordersPerDay = List.filled(7, 0);

      // Iterate over the orders and count them per day
      for (var doc in snapshot.docs) {
        Timestamp pickupTimestamp = doc['pickupTime']; // Fetch the pickupTime field
        DateTime pickupDate = pickupTimestamp.toDate();

        // Calculate the index of the day of the week (0 = Monday, 6 = Sunday)
        int dayOfWeek = pickupDate.weekday - 1; // Adjust to 0-based index

        // Increment the orders for that day
        ordersPerDay[dayOfWeek]++;
      }

      // Update the UI with the fetched data
      setState(() {
        weeklyOrders = ordersPerDay;
        isLoading = false;
        print("Fetched weeklyOrders: $weeklyOrders");
      });
    } catch (e) {
      print('Error fetching weekly orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }



  // Method to pick a start date for the week
  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime(2020), // Set a reasonable range for the past dates
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedStartDate) {
      setState(() {
        selectedStartDate = picked;
      });
      _generateWeekDates(picked);
      fetchWeeklyOrderData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildWeeklyOrdersChart(context),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardTile(
                    context,
                    'Orders',
                    Icons.list,
                    Colors.white,
                    VOrdersPages(),
                  ),
                  _buildDashboardTile(
                    context,
                    'Products',
                    Icons.inventory,
                    Colors.white,
                    ProductListScreen(uid: widget.uid),
                  ),
                  _buildDashboardTile(
                    context,
                    'Insights',
                    Icons.bar_chart,
                    Colors.white,
                    InsightPage(uid: widget.uid),
                  ),
                  _buildDashboardTile(
                    context,
                    'Profile',
                    Icons.person,
                    Colors.white,
                    VendorDetailsCardPage(uid: widget.uid),
                  ),
                  _buildDashboardTile(
                    context,
                    'Support',
                    Icons.support_agent,
                    Colors.white,
                    VendorSupportPage(uid: widget.uid),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOrdersChart(BuildContext context) {
    List<BarChartGroupData> weeklyOrdersData = List.generate(7, (index) {
      // Slightly shift the bars to the left by adjusting the x-axis position
      return _createBarChartData(index - 0.3, weeklyOrders[index]); // Shift left by 0.3
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.7), Colors.cyanAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Orders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _pickStartDate(context),
                    tooltip: "Select Week Start Date",
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: weeklyOrdersData, // barGroups is defined here
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false), // gridData is defined here
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Disable right Y-axis titles
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1, // Increase spacing between the dates
                          getTitlesWidget: (double value, _) {
                            return Text(
                              weekDates.isNotEmpty && value.toInt() < weekDates.length
                                  ? weekDates[value.toInt()]
                                  : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12, // Adjust font size for better spacing
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _createBarChartData(double x, double y) {
    return BarChartGroupData(
      x: x.toInt(), // Ensure x is an integer for correct positioning
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.white,
          width: 16, // Adjusted width for the bar
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTile(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      Widget page,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: color,
        elevation: 4, // Added elevation for better shadow effect
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50, // Larger icon for better visibility
                color: Colors.blueAccent, // Blue accent color for the icon
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Dark color for title text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import '../../no_internet.dart';
import '../../widgets/shimmer.dart';
import '../Cart/cart.dart';
import '../Cart/cart_provider.dart';
import 'PopularDetailsBody2.dart';

class AverageDhobiPage extends StatefulWidget {
  @override
  _AverageDhobiPageState createState() => _AverageDhobiPageState();
}

class _AverageDhobiPageState extends State<AverageDhobiPage> {
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _dhobiDocs = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 4;
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
    _fetchDhobis();
    _scrollController.addListener(_scrollListener);
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

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore) {
      _fetchDhobis();
    }
  }

  Future<void> _fetchDhobis() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot dhobiSnapshot =
          await FirebaseFirestore.instance.collection('dhobi').limit(1).get();
      List<DocumentSnapshot> averageDhobiList = [];

      for (var dhobiDoc in dhobiSnapshot.docs) {
        Query query = dhobiDoc.reference
            .collection('Average dhobi')
            .orderBy('name')
            .limit(_pageSize);

        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        QuerySnapshot averageSnapshot = await query.get();

        if (averageSnapshot.docs.isNotEmpty) {
          for (var doc in averageSnapshot.docs) {
            // Validate that essential fields are present
            final data = doc.data() as Map<String, dynamic>?;

            if (data != null && _isDhobiDataComplete(data)) {
              averageDhobiList.add(doc);
              _lastDocument = doc; // Update the last document for pagination
            }
          }
        }
      }

      setState(() {
        _dhobiDocs.addAll(averageDhobiList);
        _hasMore = averageDhobiList.length == _pageSize;
      });
    } catch (e) {
      print('Error fetching Laundries: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching Laundries. Please try again later.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isDhobiDataComplete(Map<String, dynamic> data) {
    // Check if essential fields are not null or empty
    return data['name'] != null &&
        data['description'] != null &&
        data['rating'] != null &&
        (data['imageUrl'] as List<dynamic>?)?.isNotEmpty == true &&
        (data['services'] as List<dynamic>?)?.isNotEmpty == true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _internetConnectionStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      actions: [
        Consumer<CombinedDhobiCartProvider>(
            builder: (context, cartProvider, child) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartsPage()),
            ),
            child: _buildCartIcon(cartProvider),
          );
        }),
      ],
    );
  }

  Widget _buildCartIcon(CombinedDhobiCartProvider cartProvider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.shopping_cart, color: Colors.green),
        ),
        if (cartProvider.totalItems() > 0) _buildCartItemCount(cartProvider),
      ],
    );
  }

  Widget _buildCartItemCount(CombinedDhobiCartProvider cartProvider) {
    return Positioned(
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Text(
          '${cartProvider.totalItems()}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dhobiDocs.isEmpty) {
      return const Center(child: ShimmerLoading());
    }

    if (_dhobiDocs.isEmpty) {
      return const Center(
          child: Text('No Laundries found. Please check back later.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(15.0),
      itemCount: _dhobiDocs.length +
          (_hasMore ? 1 : 0) +
          (!_hasMore && !_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _dhobiDocs.length) {
          return _buildAverageDhobi(_dhobiDocs[index]);
        } else if (_hasMore) {
          return _buildLoadingIndicator(); // Show loading indicator for pagination
        } else {
          return _buildNoMoreDataMessage(); // Show no more data message
        }
      },
    );
  }

  Widget _buildNoMoreDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Center the content
          children: [
            // Load your GIF here using a network URL
            Image.network(
              'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/gif%2Floading.gif?alt=media&token=7c51eb1e-d628-4d6f-b99c-fb4264ab7fc0', // Replace with your GIF URL
              height: 100, // Set the desired height
              width: 100, // Set the desired width
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error,
                    size: 100,
                    color: Colors.red); // Fallback if the GIF fails to load
              },
            ),
            const SizedBox(
                height: 10), // Add some space between the GIF and the text
            const Text(
              'Wash_it - One Step Towards Cleaning',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(), // Add loading spinner here
      ),
    );
  }

  Widget _buildAverageDhobi(DocumentSnapshot dhobiDoc) {
    final data = dhobiDoc.data() as Map<String, dynamic>?;

    if (data == null) {
      return const Center(child: Text('No Average Laundries found.'));
    }

    final name = data['name'] ?? 'Unnamed';
    final description = data['description'] ?? 'No description';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final images = List<String>.from(data['imageUrl'] ?? []);
    final services = List<String>.from(data['services'] ?? []);

    return InkWell(
      onTap: () => _onDhobiTap(dhobiDoc.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCarousel(images),
              const SizedBox(height: 10),
              _buildDhobiInfo(name, description, rating, services),
            ],
          ),
        ),
      ),
    );
  }

  void _onDhobiTap(String dhobiId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AverageDetailsBody(
                averageDhobiId: dhobiId,
              )),
    );
  }

  Widget _buildCarousel(List<String> images) {
    if (images.isEmpty) {
      return const SizedBox(
        height: 150,
        child: ShimmerLoading(),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 150,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        viewportFraction: 0.8,
      ),
      items: images.map((imageUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDhobiInfo(
      String name, String description, double rating, List<String> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 5),
            Text(rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: services.map((service) {
            return Chip(
                label: Text(service), backgroundColor: Colors.green[100]);
          }).toList(),
        ),
      ],
    );
  }
}

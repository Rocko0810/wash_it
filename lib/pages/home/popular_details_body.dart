import 'dart:async';

import 'package:flutter/material.dart';
import 'package:horizontal_text_line/horizontal_text_line.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import '../../Dimensions/dimensions.dart';
import '../../no_internet.dart';
import '../../widgets/big_text.dart';
import '../../widgets/icon_and_text_widget.dart';
import '../../widgets/shimmer.dart';
import '../../widgets/small_text.dart';
import '../Cart/cart.dart';
import '../Cart/cart_provider.dart';

class PopularDetailsBody extends StatefulWidget {
  final String premiumDhobiId;

  const PopularDetailsBody({Key? key, required this.premiumDhobiId}) : super(key: key);

  @override
  _PopularDetailsBodyState createState() => _PopularDetailsBodyState();
}
class _PopularDetailsBodyState extends State<PopularDetailsBody> {
  PageController pageController = PageController(); // Page controller for images
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription _internetConnectionStreamSubscription;

  List<dynamic> productImage = [];
  List<dynamic> productName = [];
  List<double> productPrice = [];
  List<dynamic> imageUrl = [];
  late List<int> quantities;

  bool isLoading = true; // Indicates loading state
  String? fetchedName;
  String? fetchedServices;
  double? fetchedStar;
  String? fetchedDistance;
  String? fetchedDelivery;
  String? fetchedSpeed;
  String? fetchedVendorId;
  String searchQuery = ''; // Search query variable

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
    fetchDataFromCollection();
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


  Future<void> fetchDataFromCollection() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      DocumentSnapshot premiumDhobiDoc = await _firestore
          .collection('dhobi')
          .doc('FwLIVilNtChUZzLbceDS')
          .collection('Premium dhobi')
          .doc(widget.premiumDhobiId)
          .get();

      if (premiumDhobiDoc.exists) {
        var data = premiumDhobiDoc.data() as Map<String, dynamic>;

        fetchedName = data['name'] ?? "";
        fetchedVendorId = data['vendorId'] ?? "Random";
        fetchedStar = (data['rating'] as num?)?.toDouble() ?? 0.0;
        fetchedServices = data['service'] ?? "";
        fetchedDelivery = data['delivery time'] ?? "";
        fetchedSpeed = data['delivery speed'] ?? "";
        fetchedDistance = data['distance'] ?? "";


        imageUrl = List<String>.from(data['imageUrl'] ?? []);
        productImage = List<String>.from(data['productImage'] ?? []);
        productName = List<String>.from(data['productName'] ?? []);
        productPrice = (data['productPrice'] as List<dynamic>?)
            ?.map((item) => (item is num) ? item.toDouble() : 0.0)
            .toList() ??
            [];

        quantities = List<int>.filled(productName.length, 0); // Initialize quantities
      } else {
        print("No document found for this premium dhobi.");
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void _incrementQuantity(int index) {
    setState(() {
      quantities[index]++;
    });
  }

  void _decrementQuantity(int index) {
    if (quantities[index] > 0) {
      setState(() {
        quantities[index]--;
      });
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    _internetConnectionStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<int> filteredIndices = [];
    for (int i = 0; i < productName.length; i++) {
      if (productName[i].toLowerCase().contains(searchQuery.toLowerCase())) {
        filteredIndices.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        actions: [
          Consumer<CombinedDhobiCartProvider>(
            builder: (context, cartProvider, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartsPage()),
                  );
                },
                child: Stack(
                  children: [
                    Padding(padding: EdgeInsets.only(right: Dimensions.Width40)),
                    const Icon(Icons.shopping_cart, color: Colors.green),
                    if (cartProvider.totalItems() > 0)
                      Positioned(
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${cartProvider.totalItems()}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: ShimmerLoading())
          : SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for products...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(
              height: Dimensions.pageView,
              child: PageView.builder(
                controller: pageController,
                itemCount: 1,
                itemBuilder: (context, position) {
                  return _buildPageItem(position);
                },
              ),
            ),
            const SizedBox(height: 30),
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HorizontalTextLine(text: "Wash & Iron", color: Colors.grey),
            if (filteredIndices.isNotEmpty)
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true, // Ensures ListView takes only the required space
                itemCount: filteredIndices.length,
                itemBuilder: (context, index) {
                  int productIndex = filteredIndices[index];
                  return _buildProductCard(context, productIndex);
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0), // Optional padding
                  child: Text(
                    "No products found",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildPageItem(int index) {
    return Stack(
      children: [
        Positioned(
          top: Dimensions.Height20,
          left: Dimensions.Width10,
          right: Dimensions.Width10,
          child: SizedBox(
            width: double.infinity,
            height: Dimensions.popularWashImgSize,
            child: Image.network(
              imageUrl.isNotEmpty ? imageUrl[0] : '',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: Dimensions.Height45*3,
            margin: EdgeInsets.only(
              left: Dimensions.Width20,
              right: Dimensions.Width30,
              bottom: Dimensions.Height10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radius20),
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(5, 5))],
            ),
            child: Padding(
              padding: EdgeInsets.all(Dimensions.Width10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigText(text: fetchedName ?? "Loading..."),
                  SizedBox(height: Dimensions.Height10),
                  Row(
                    children: [
                      Wrap(
                        children: List.generate(
                          fetchedStar?.floor() ?? 0,
                              (index) => const Icon(Icons.star, color: Colors.red, size: 15),
                        ) +
                            (fetchedStar != null && fetchedStar! % 1 >= 0.5
                                ? [const Icon(Icons.star_half, color: Colors.red, size: 15)]
                                : []),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 20,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: SmallText(
                            text: "${fetchedStar ?? 0}*",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.Height20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconAndTextWidget(
                        icon: Icons.card_giftcard_outlined,
                        text: fetchedSpeed ?? "Loading",
                        iconColor: Colors.red,
                      ),
                      IconAndTextWidget(
                        icon: Icons.location_on,
                        text: fetchedDistance ?? "Loading",
                        iconColor: Colors.red,
                      ),
                      IconAndTextWidget(
                        icon: Icons.watch_later_outlined,
                        text: fetchedDelivery ?? "Loading",
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, int productIndex) {
    return Container(
      margin: EdgeInsets.only(
        left: Dimensions.Width20,
        right: Dimensions.Width20,
        bottom: Dimensions.Height10,
      ),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(Dimensions.radius20),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.all(Dimensions.Width10),
              width: Dimensions.listviewImgWidth,
              height: Dimensions.listviewImgHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radius20),
                image: DecorationImage(
                  image: NetworkImage(productImage[productIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.Width10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigText(text: productName[productIndex]),
                    SizedBox(height: Dimensions.Height10),
                    BigText(
                      text: '₹${productPrice[productIndex]}',
                      color: Colors.green,
                    ),
                    _buildQuantitySelector(context, productIndex),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int productIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Quantity increment and decrement buttons
        Container(
          height: Dimensions.Height30,
          padding: EdgeInsets.symmetric(horizontal: Dimensions.Width5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _decrementQuantity(productIndex),
                child: const Icon(Icons.remove, color: Colors.black),
              ),
              SizedBox(width: Dimensions.Width20),
              BigText(text: "${quantities[productIndex]}"),
              SizedBox(width: Dimensions.Width20),
              GestureDetector(
                onTap: () => _incrementQuantity(productIndex),
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
        ),
        Consumer<CombinedDhobiCartProvider>(
          builder: (context, cartProvider, child) {
            return GestureDetector(
              onTap: () {
                if (quantities[productIndex] > 0) {
                  // Check if the item belongs to a different vendor
                  if (cartProvider.currentDhobiId != null &&
                      cartProvider.currentDhobiId != fetchedVendorId) {
                    // Show a dialog to confirm clearing the cart
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Different Vendor Detected"),
                          content: const Text(
                            "Adding this item will clear the current cart. Do you want to proceed?",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Proceed"),
                              onPressed: () {
                                cartProvider.clearCart(); // Clear the cart
                                cartProvider.addItem(
                                  productName[productIndex],
                                  quantities[productIndex],
                                  productPrice[productIndex],
                                  fetchedName!,
                                  fetchedVendorId!,
                                );
                                Navigator.of(context).pop(); // Close the dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${productName[productIndex]} added to cart'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                setState(() {
                                  quantities[productIndex] = 0;
                                });
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // If the vendor is the same, proceed with adding the item
                    cartProvider.addItem(
                      productName[productIndex],
                      quantities[productIndex],
                      productPrice[productIndex],
                      fetchedName!,
                      fetchedVendorId!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${productName[productIndex]} added to cart'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    setState(() {
                      quantities[productIndex] = 0;
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a quantity before adding to cart'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                height: Dimensions.Height30,
                width: Dimensions.Width30 * 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green,
                ),
                child: Center(
                  child: BigText(text: "ADD", color: Colors.white),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';

class ProductListScreen extends StatelessWidget {
  final String uid; // Vendor's unique ID

  ProductListScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _addProduct(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(); // Use shimmer effect while loading
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading products'));
          }

          final products = snapshot.data?.docs ?? [];
          if (products.isEmpty) {
            return _buildDummyProduct();
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: _buildProductImage(product['productImage']),
                title: Text(product['productName'] ?? 'Unnamed Product'),
                subtitle: Text('Price: ₹${product['productPrice']}'),
                trailing: _buildActionButtons(context, product),
              );
            },
          );
        },
      ),
    );
  }

  // Build action buttons for edit and delete
  Widget _buildActionButtons(BuildContext context, QueryDocumentSnapshot product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _editProduct(context, product);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _confirmDelete(context, product);
          },
        ),
      ],
    );
  }

  // Build shimmer loading effect
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              color: Colors.white,
            ),
            title: Container(
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 14,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  // Build product image with a fallback to dummy image
  Widget _buildProductImage(String? imageUrl) {
    const String dummyImageUrl =
        'https://firebasestorage.googleapis.com/v0/b/washit-25714.appspot.com/o/profile_pictures%2Fprofile001.png?alt=media&token=d45b08ab-bb2f-49aa-81d1-fc6376776cd3'; // Replace with your dummy image URL

    return Image.network(
      imageUrl ?? dummyImageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  // Display dummy product tile if no products exist
  Widget _buildDummyProduct() {
    return Center(
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, size: 50, color: Colors.grey),
        title: const Text('No Products Found'),
        subtitle: const Text('Please add some products.'),
      ),
    );
  }

  // Add a new product
  Future<void> _addProduct(BuildContext context) async {
    final result = await _showProductDialog(context, 'Add Product');
    if (result != null) {
      final newProduct = {
        'productName': result['productName'], // Ensure keys match
        'productPrice': result['productPrice'],
        'productImage': result['productImage'],
      };
      try {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('products')
            .add(newProduct);
        _showSnackBar(context, 'Product added successfully!');
      } catch (e) {
        _showSnackBar(context, 'Failed to add product: ${e.toString()}'); // Detailed error message
      }
    }
  }

  // Edit an existing product
  Future<void> _editProduct(BuildContext context, QueryDocumentSnapshot product) async {
    final result = await _showProductDialog(
      context,
      'Edit Product',
      initialName: product['productName'],
      initialPrice: product['productPrice'],
      initialImageUrl: product['productImage'],
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('products')
            .doc(product.id)
            .update(result);
        _showSnackBar(context, 'Product updated successfully!');
      } catch (e) {
        _showSnackBar(context, 'Failed to update product: ${e.toString()}'); // Detailed error message
      }
    }
  }

  // Confirm and delete a product
  Future<void> _confirmDelete(BuildContext context, QueryDocumentSnapshot product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('products')
            .doc(product.id)
            .delete();
        _showSnackBar(context, 'Product deleted successfully!');
      } catch (e) {
        _showSnackBar(context, 'Failed to delete product: ${e.toString()}'); // Detailed error message
      }
    }
  }

  // Show dialog for adding or editing a product
  Future<Map<String, dynamic>?> _showProductDialog(
      BuildContext context,
      String title, {
        String? initialName,
        int? initialPrice,
        String? initialImageUrl,
      }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return ProductDialog(
          title: title,
          initialName: initialName,
          initialPrice: initialPrice,
          initialImageUrl: initialImageUrl,
        );
      },
    );
  }

  // Show a snackbar message
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final int? initialPrice;
  final String? initialImageUrl;

  ProductDialog({
    required this.title,
    this.initialName,
    this.initialPrice,
    this.initialImageUrl,
  });

  @override
  _ProductDialogState createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  String? imageUrl;
  String? imageWarning; // Variable to hold the warning message
  bool isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    priceController = TextEditingController(text: widget.initialPrice?.toString() ?? '');
    imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Enter product name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(hintText: 'Enter product price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _buildImagePicker(context),
            if (imageWarning != null) // Show warning if there is one
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  imageWarning!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveProduct,
          child: isLoading
              ? const CircularProgressIndicator() // Show loading indicator when saving
              : const Text('Save'),
        ),
      ],
    );
  }

  // Image picker with validation
  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 150,
        color: Colors.grey[300],
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : const Icon(Icons.add_a_photo, color: Colors.black),
      ),
    );
  }

// Pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File file = File(image.path);
      final int imageSize = await file.length(); // Get the file size in bytes

      if (imageSize > 300 * 1024) { // Check if the size is greater than 300 KB
        setState(() {
          imageWarning = 'Image size should be less than or equal to 300 KB.';
        });
        return;
      }

      setState(() {
        isLoading = true; // Start loading when picking an image
        imageWarning = null; // Clear previous warnings
      });

      final uploadResult = await _uploadImageToFirebase(image.path);
      if (uploadResult != null) {
        setState(() {
          imageUrl = uploadResult;
          isLoading = false; // Stop loading after upload
        });
      } else {
        setState(() {
          imageWarning = 'Failed to upload image. Please try again.';
          isLoading = false; // Stop loading if there's an error
        });
      }
    } else {
      setState(() {
        imageWarning = 'No image selected.'; // Update warning if no image is selected
      });
    }
  }


  // Upload image to Firebase Storage
  Future<String?> _uploadImageToFirebase(String filePath) async {
    try {
      final File file = File(filePath);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(file);
      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null; // Return null if upload fails
    }
  }

  // Save product and validate inputs
  void _saveProduct() {
    final name = nameController.text.trim();
    final priceString = priceController.text.trim();
    final price = int.tryParse(priceString);

    if (name.isEmpty) {
      _showWarning('Product name cannot be empty.');
      return;
    }
    if (price == null) {
      _showWarning('Please enter a valid price.');
      return;
    }
    if (imageUrl == null) {
      _showWarning('Please select an image.');
      return;
    }

    Navigator.of(context).pop({
      'productName': name,
      'productPrice': price,
      'productImage': imageUrl,
    });
  }

  // Show warning messages
  void _showWarning(String message) {
    setState(() {
      imageWarning = message; // Show warning message
    });
  }
}

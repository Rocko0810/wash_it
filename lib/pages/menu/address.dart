import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wash_it/Dimensions/dimensions.dart';
import 'package:wash_it/widgets/small_text.dart';

import '../../widgets/big_text.dart';
import '../../widgets/defaulttext.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({Key? key}) : super(key: key);

  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedAddressType = 'Home'; // Default value
  bool _isLoading = false; // Loading indicator
  bool _isLocating = false; // Loading indicator for locating
  String? _editingAddressId; // To keep track of editing state
  bool _isDefaultAddress = false; // Track if this address is default

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save or update the address
  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // Create a map of the form data
        Map<String, dynamic> addressData = {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zip': _zipController.text.trim(),
          'phone': _phoneController.text.trim(),
          'addressType': _selectedAddressType,
          'isDefault': _isDefaultAddress, // Mark as default
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Check if the address is set as default
        if (_isDefaultAddress) {
          // If it's a default address, update other addresses to set their isDefault to false
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              // Update other addresses
              doc.reference.update({'isDefault': false});
            }
          });
        }

        if (_editingAddressId == null) {
          // Add a new address
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .add(addressData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Address saved successfully!')),
          );
        } else {
          // Update an existing address
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .doc(_editingAddressId)
              .update(addressData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Address updated successfully!')),
          );
        }

        // Clear the form and reset editing state
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to get the current location and fill the address fields
  Future<void> _locateMe() async {
    setState(() {
      _isLocating = true; // Start loading for locating button
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      // Check for location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are permanently denied.')),
        );
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      // Fill the form fields with location data
      setState(() {
        _addressController.text = place.street ?? '';
        _cityController.text = place.locality ?? '';
        _stateController.text = place.administrativeArea ?? '';
        _zipController.text = place.postalCode ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isLocating = false; // Stop loading for locating button
      });
    }
  }

  // Load an address for editing
  void _editAddress(DocumentSnapshot addressSnapshot) {
    setState(() {
      _editingAddressId = addressSnapshot.id;
      _nameController.text = addressSnapshot['name'] ?? '';
      _addressController.text = addressSnapshot['address'] ?? '';
      _cityController.text = addressSnapshot['city'] ?? '';
      _stateController.text = addressSnapshot['state'] ?? '';
      _zipController.text = addressSnapshot['zip'] ?? '';
      _phoneController.text = addressSnapshot['phone'] ?? '';
      _selectedAddressType = addressSnapshot['addressType'] ?? 'Home';
      _isDefaultAddress = addressSnapshot['isDefault'] ?? false; // Load the default state
    });
  }

  // Clear the form and reset the editing state
  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipController.clear();
    _phoneController.clear();
    _selectedAddressType = 'Home';
    _editingAddressId = null;
    _isDefaultAddress = false; // Reset the default state
  }

  // Build the list of saved addresses
  Widget _buildAddressList() {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No saved addresses found.'));
        }

        List<DocumentSnapshot> addresses = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            var address = addresses[index].data() as Map<String, dynamic>;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radius12),
              ),
              elevation: 5,
              color: Colors.green.shade50, // Adding color to the address card
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: DefaultText(text:
                    address['name'] ?? '',
                    color: Colors.green,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Dimensions.Height10/2),
                      Text('Address: ${address['address'] ?? ''}'),
                      Text('City: ${address['city'] ?? ''}'),
                      Text('State: ${address['state'] ?? ''}'),
                      Text('ZIP Code: ${address['zip'] ?? ''}'),
                      Text('Phone: ${address['phone'] ?? ''}'),
                      Text('Type: ${address['addressType'] ?? ''}'),
                      if (address['isDefault'] == true)
                        DefaultText(
                          text: 'Default Address',
                          color: Colors.green,

                        ), // Indicate default address
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.green),
                    onPressed: () =>
                        _editAddress(addresses[index]), // Load address for editing
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BigText(text: _editingAddressId == null ? 'Add Address' : 'Edit Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(labelText: 'State'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your state';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                TextFormField(
                  controller: _zipController,
                  decoration: InputDecoration(labelText: 'ZIP Code'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ZIP code';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isLocating
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Icon(Icons.my_location, color: Colors.red),
                        label: SmallText(
                          text: _isLocating ? 'Locating...' : 'Use Current Location',
                        ),
                        onPressed: _isLocating ? null : _locateMe, // Disable when locating
                        style: ElevatedButton.styleFrom(
                          //backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radius10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.Height10),
                DropdownButtonFormField<String>(
                  value: _selectedAddressType,
                  items: ['Home', 'Work', 'Other']
                      .map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: SmallText(text:type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAddressType = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Address Type'),
                ),
                SizedBox(height: Dimensions.Height10),
                CheckboxListTile(
                  title: Text('Set as Default Address'),
                  value: _isDefaultAddress,
                  onChanged: (value) {
                    setState(() {
                      _isDefaultAddress = value ?? false;
                    });
                  },
                ),
                SizedBox(height: Dimensions.Height10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text(_editingAddressId == null ? 'Save Address' : 'Update Address' , style: TextStyle(color: Colors.black),),
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radius10),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.Height20),
                BigText(
                  text: 'Saved Addresses',
                ),
                SizedBox(height: Dimensions.Height10),
                _buildAddressList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

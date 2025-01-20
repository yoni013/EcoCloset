import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/main.dart';
import 'package:flutter/material.dart';

class OnboardingForm extends StatefulWidget {
  final String userId;

  const OnboardingForm({Key? key, required this.userId}) : super(key: key);

  @override
  _OnboardingFormState createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<OnboardingForm> {
  final _formKey = GlobalKey<FormState>();
  String? age;
  String? preferredShirtSize;
  String? pantsSize;
  String? shoeSize;
  String? preferredBrands;
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          userName = docSnapshot.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _submitForm() async {
    _formKey.currentState!.save();

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .update({
      'age': age ?? '',
      'preferred_shirt_size': preferredShirtSize ?? '',
      'pants_size': pantsSize ?? '',
      'shoe_size': shoeSize ?? '',
      'preferred_brands': preferredBrands ?? '',
      'isNewUser': false, // Mark as no longer a new user
    });

    print('OnboardingForm: Profile submitted successfully.');
    _navigateToHomePage();
  }

  void _navigateToHomePage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => PersistentBottomNavPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width *
            0.9, // Make the popup almost as wide as the screen
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Get better recommendations by updating your profile!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Age',
                      keyboardType: TextInputType.number,
                      onSaved: (value) => age = value,
                    ),
                    _buildTextField(
                      label: 'Preferred Shirt Size',
                      onSaved: (value) => preferredShirtSize = value,
                    ),
                    _buildTextField(
                      label: 'Pants Size',
                      onSaved: (value) => pantsSize = value,
                    ),
                    _buildTextField(
                      label: 'Shoe Size',
                      onSaved: (value) => shoeSize = value,
                    ),
                    _buildTextField(
                      label: 'Preferred Brands',
                      onSaved: (value) => preferredBrands = value,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _navigateToHomePage,
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: keyboardType,
        onSaved: onSaved,
      ),
    );
  }
}

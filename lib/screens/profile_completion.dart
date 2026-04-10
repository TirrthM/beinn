import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome.dart';
import '../main.dart';
import 'dart:async';

class ProfileCompletionScreen extends StatefulWidget {
  final User user;

  ProfileCompletionScreen({required this.user});

  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buildingController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  // State variables
  String _selectedGender = '';
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prefillUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  void _prefillUserData() {
    // Pre-fill name from Google account
    if (widget.user.displayName != null) {
      final nameParts = widget.user.displayName!.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
    }
  }

  bool _isValidIndianMobile(String number) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(number);
  }

  bool _isDummyNumber(String number) {
    return RegExp(r'(.)\1{9}').hasMatch(number);
  }

  Future<bool> _showPhoneConfirmationDialog(String number) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Please confirm your mobile number',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order updates and delivery OTP will be sent to this number.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    text: 'Mobile Number: ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    children: [
                      TextSpan(
                        text: number,
                        style: TextStyle(
                          color: Color(0xFFBB694A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Edit', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBB694A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    if (_selectedGender.isEmpty) {
      _showSnackBar('Please select your gender');
      return;
    }

    final confirmed = await _showPhoneConfirmationDialog(_phoneController.text);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save complete profile to Firestore
      await _firestore.collection('users').doc(widget.user.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'gender': _selectedGender,
        'phone': '+91${_phoneController.text}',
        'phoneVerified': true,
        'address': {
          'building': _buildingController.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'area': _areaController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'profileComplete': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });

      print('Profile completed successfully');
      _navigateToHome();
    } catch (e) {
      print('Error completing profile: $e');
      _showSnackBar('Error saving profile. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFBB694A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white),
        validator: required
            ? (value) =>
                value?.isEmpty ?? true ? 'This field is required' : null
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFBB694A)),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: const Color(0xFFBB694A)),
                SizedBox(width: 12),
                Text(
                  'Gender',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Male'
                            ? Color(0xFFBB694A).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Male'
                              ? Color(0xFFBB694A)
                              : Colors.grey[700]!,
                        ),
                      ),
                      child: Text(
                        'Male',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Male'
                              ? Color(0xFFBB694A)
                              : Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Female'
                            ? Color(0xFFBB694A).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Female'
                              ? Color(0xFFBB694A)
                              : Colors.grey[700]!,
                        ),
                      ),
                      child: Text(
                        'Female',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Female'
                              ? Color(0xFFBB694A)
                              : Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Other'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Other'
                            ? Color(0xFFBB694A).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Other'
                              ? Color(0xFFBB694A)
                              : Colors.grey[700]!,
                        ),
                      ),
                      child: Text(
                        'Other',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Other'
                              ? Color(0xFFBB694A)
                              : Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Country Code
          Container(
            width: 75,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[800]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('\u{1F1EE}\u{1F1F3}', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 3),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          // Phone Number Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[800]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Phone number is required';
                  if (!_isValidIndianMobile(value!))
                    return 'Enter valid 10-digit number (Starts with 6-9)';
                  if (_isDummyNumber(value))
                    return 'Invalid number pattern (e.g. 1111111111)';
                  return null;
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: const Color(0xFFBB694A)),
                  labelText: 'Mobile Number',
                  hintText: 'Enter 10-digit number',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
          ),
        ),
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFBB694A).withOpacity(0.1),
                          Color(0xFFBB694A).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFBB694A).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_add, color: Color(0xFFBB694A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Almost There!',
                                style: TextStyle(
                                  color: Color(0xFFBB694A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Complete your profile to start shopping with Beinn. We need these details to process your orders and deliveries.',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Personal Information Section
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    icon: Icons.person_outline,
                  ),

                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    icon: Icons.person_outline,
                  ),

                  _buildGenderSelector(),

                  SizedBox(height: 24),

                  // Contact Information Section
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildPhoneField(),

                  SizedBox(height: 24),

                  // Address Information Section
                  Text(
                    'Address Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    controller: _buildingController,
                    label: 'Building/House No.',
                    hint: 'Enter building or house number',
                    icon: Icons.home_outlined,
                  ),

                  _buildTextField(
                    controller: _landmarkController,
                    label: 'Landmark',
                    hint: 'Enter nearby landmark',
                    icon: Icons.location_on_outlined,
                    required: false,
                  ),

                  _buildTextField(
                    controller: _areaController,
                    label: 'Area/Street',
                    hint: 'Enter area or street name',
                    icon: Icons.map_outlined,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'Enter city',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _stateController,
                          label: 'State',
                          hint: 'Enter state',
                          icon: Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: 'Enter 6-digit pincode',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Complete Profile Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBB694A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Color(0xFFBB694A).withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Complete Profile',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}

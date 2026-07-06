import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';

class NewAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  final bool isEditing;

  const NewAddressScreen({
    super.key,
    this.existingAddress,
    this.isEditing = false,
  });

  @override
  State<NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _buildingController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Form state
  String _selectedGender = 'Male';
  String _selectedAddressType = 'HOME';
  bool _loading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prefillData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  void _prefillData() {
    if (widget.existingAddress != null) {
      final data = widget.existingAddress!;
      _firstNameController.text = data['firstName']?.toString() ?? '';
      _lastNameController.text = data['lastName']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? '';
      _mobileController.text = data['mobile']?.toString() ?? '';

      // Handle nested address data correctly
      _buildingController.text = data['building']?.toString() ?? '';
      _landmarkController.text = data['landmark']?.toString() ?? '';
      _areaController.text = data['area']?.toString() ?? '';
      _cityController.text = data['city']?.toString() ?? '';
      _stateController.text = data['state']?.toString() ?? '';
      _pincodeController.text = data['pincode']?.toString() ?? '';

      final gender = data['gender']?.toString() ?? '';
      if (gender.toLowerCase().startsWith('f')) {
        _selectedGender = 'Female';
      } else if (gender.toLowerCase().startsWith('o')) {
        _selectedGender = 'Other';
      } else {
        _selectedGender = 'Male';
      }

      _selectedAddressType = data['addressType']?.toString() ?? 'HOME';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    // Email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Mobile validation
    if (_mobileController.text.trim().length != 10) {
      _showSnackBar('Please enter a valid 10-digit mobile number');
      return;
    }

    // Pincode validation
    if (_pincodeController.text.trim().length != 6) {
      _showSnackBar('Please enter a valid 6-digit pincode');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final addressData = {
        'fullName':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'gender': _selectedGender,
        'address': {
          'building': _buildingController.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'area': _areaController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'addressType': _selectedAddressType,
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEditing && widget.existingAddress != null) {
        final addressId = widget.existingAddress!['id'];
        if (addressId != null && addressId != 'main_profile') {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('saved_addresses')
              .doc(addressId)
              .update(addressData);
          _showSnackBar('Address updated successfully!');
        } else {
          _showSnackBar('Cannot edit this address');
          return;
        }
      } else {
        addressData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('saved_addresses')
            .add(addressData);
        _showSnackBar('Address added successfully!');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      _showSnackBar('Failed to save address. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBB694A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        validator: required
            ? (value) =>
                value?.isEmpty ?? true ? 'This field is required' : null
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFBB694A)),
          labelText: label,
          hintText: hint,
          labelStyle:
              TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          hintStyle:
              TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFFBB694A)),
                const SizedBox(width: 12),
                Text(
                  'Gender',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Male'
                            ? const Color(0xFFBB694A).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Male'
                              ? const Color(0xFFBB694A)
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Male',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Male'
                              ? const Color(0xFFBB694A)
                              : (isDark ? Colors.grey[300] : Colors.grey[600]),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Female'
                            ? const Color(0xFFBB694A).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Female'
                              ? const Color(0xFFBB694A)
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Female',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Female'
                              ? const Color(0xFFBB694A)
                              : (isDark ? Colors.grey[300] : Colors.grey[600]),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Other'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Other'
                            ? const Color(0xFFBB694A).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedGender == 'Other'
                              ? const Color(0xFFBB694A)
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Other',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedGender == 'Other'
                              ? const Color(0xFFBB694A)
                              : (isDark ? Colors.grey[300] : Colors.grey[600]),
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

  Widget _buildPhoneField(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Country Code
          Container(
            width: 75,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('\u{1F1EE}\u{1F1F3}',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 3),
                    Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Phone Number Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Mobile number is required';
                  }
                  if (value!.length != 10) return 'Enter valid 10-digit number';
                  return null;
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: Color(0xFFBB694A)),
                  labelText: 'Mobile Number',
                  hintText: 'Enter 10-digit number',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTypeSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label_outline, color: Color(0xFFBB694A)),
                const SizedBox(width: 12),
                Text(
                  'Address Type',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final type in ['HOME', 'WORK', 'OTHER'])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: type == 'HOME' ? 0 : 6,
                          right: type == 'OTHER' ? 0 : 6),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedAddressType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedAddressType == type
                                ? const Color(0xFFBB694A).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedAddressType == type
                                  ? const Color(0xFFBB694A)
                                  : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedAddressType == type
                                  ? const Color(0xFFBB694A)
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[600]),
                              fontWeight: FontWeight.w500,
                            ),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Scaffold(
            backgroundColor: isDark
                ? Colors.black
                : const Color.fromARGB(255, 250, 249, 245), // #FAF9F5
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.isEditing ? 'Edit Address' : 'Add New Address',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFBB694A).withValues(alpha: 0.1),
                                const Color(0xFFBB694A).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFBB694A)
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: Color(0xFFBB694A)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Almost There!',
                                    style: TextStyle(
                                      color: Color(0xFFBB694A),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isEditing
                                    ? 'Update your address details to ensure accurate delivery.'
                                    : 'Ensure your address details are accurate for a smooth delivery experience.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Personal Information Section
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'Enter your first name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),

                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Enter your last name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),

                        _buildGenderSelector(isDark),

                        const SizedBox(height: 24),

                        // Contact Information Section
                        Text(
                          'Contact Information',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                        ),

                        _buildPhoneField(isDark),

                        const SizedBox(height: 24),

                        // Address Information Section
                        Text(
                          'Address Information',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _buildingController,
                          label: 'Building/House No.',
                          hint: 'Enter building or house number',
                          icon: Icons.home_outlined,
                          isDark: isDark,
                        ),

                        _buildTextField(
                          controller: _landmarkController,
                          label: 'Landmark',
                          hint: 'Enter nearby landmark',
                          icon: Icons.location_on_outlined,
                          required: false,
                          isDark: isDark,
                        ),

                        _buildTextField(
                          controller: _areaController,
                          label: 'Area/Street',
                          hint: 'Enter area or street name',
                          icon: Icons.map_outlined,
                          isDark: isDark,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'Enter city',
                                icon: Icons.location_city_outlined,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'Enter state',
                                icon: Icons.map_outlined,
                                isDark: isDark,
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
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),

                        // Address Type Section
                        Text(
                          'Address Type',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildAddressTypeSelector(isDark),

                        const SizedBox(height: 32),

                        // Save Address Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB694A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFFBB694A)
                                  .withValues(alpha: 0.4),
                            ),
                            child: _loading
                                ? const SizedBox(
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
                                      Icon(
                                        widget.isEditing
                                            ? Icons.check_circle
                                            : Icons.add_location,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isEditing
                                            ? 'Update Address'
                                            : 'Save Address',
                                        style: const TextStyle(
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

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

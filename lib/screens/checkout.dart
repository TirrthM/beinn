import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'new_address.dart';
import 'order_placed.dart';
import '../theme_notifier.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CheckoutScreen({Key? key, required this.items}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _modalController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _modalAnimation;

  // Razorpay instance
  late Razorpay _razorpay;

  // Address related variables
  Map<String, dynamic>? _selectedAddress;
  String _userName = '';
  String _userEmail = '';
  String _userMobile = '';
  bool _isLoadingAddress = true;
  bool _isProcessingPayment = false;
  List<Map<String, dynamic>> _savedAddresses = [];

  String _promoCode = '';
  Map<String, dynamic>? _appliedCoupon;
  bool _isValidatingCoupon = false;
  final TextEditingController _promoCodeController = TextEditingController();
  String _selectedPaymentMethod = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserAddresses();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _modalController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    _modalAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _loadUserAddresses({bool preserveSelection = false}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final String? currentlySelectedId = _selectedAddress?['id'];

        // Load user's main profile address
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        // Load saved addresses from saved_addresses collection
        final savedAddressesSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('saved_addresses')
            .orderBy('createdAt', descending: false)
            .get();

        List<Map<String, dynamic>> allAddresses = [];

        // Add main profile address if exists
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData['address'] != null) {
            final mainAddress = {
              'id': 'main_profile',
              'fullName':
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                      .trim(),
              'email': userData['email']?.toString() ?? '',
              'mobile':
                  userData['phone']?.toString().replaceFirst('+91', '') ?? '',
              'address': userData['address'] as Map<String, dynamic>,
              'addressType': 'HOME',
              'isDefault': true,
              'isMainProfile': true,
            };
            allAddresses.add(mainAddress);
          }
        }

        // Add saved addresses
        for (var doc in savedAddressesSnapshot.docs) {
          final data = doc.data();
          allAddresses.add({
            'id': doc.id,
            'fullName': data['fullName'] ?? '',
            'email': data['email'] ?? '',
            'mobile': data['mobile'] ?? '',
            'address': data['address'] as Map<String, dynamic>,
            'addressType': data['addressType'] ?? 'HOME',
            'isDefault': data['isDefault'] ?? false,
            'isMainProfile': false,
          });
        }

        setState(() {
          _savedAddresses = allAddresses;

          // Preserve selection if requested and address still exists
          if (preserveSelection && currentlySelectedId != null) {
            final previouslySelected = allAddresses.firstWhere(
              (addr) => addr['id'] == currentlySelectedId,
              orElse: () => allAddresses.isNotEmpty ? allAddresses.first : {},
            );

            if (previouslySelected.isNotEmpty) {
              _selectedAddress = previouslySelected;
              _userName = _selectedAddress!['fullName'];
              _userEmail = _selectedAddress!['email'];
              _userMobile = _selectedAddress!['mobile'];
            }
          } else {
            // Set the first address (main profile) as selected by default only on initial load
            if (allAddresses.isNotEmpty && _selectedAddress == null) {
              _selectedAddress = allAddresses.first;
              _userName = _selectedAddress!['fullName'];
              _userEmail = _selectedAddress!['email'];
              _userMobile = _selectedAddress!['mobile'];
            }
          }

          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user addresses: $e');
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _showAddressSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddressSelectionModal(),
    );
  }

  Widget _buildAddressSelectionModal() {
    final isDark = isDarkModeNotifier.value;
    return AnimatedBuilder(
      animation: _modalAnimation,
      builder: (context, child) {
        _modalController.forward();
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Select delivery address',
                      style: TextStyle(
                        color: Color(0xFFBB694A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Saved addresses header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saved addresses',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Address list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _savedAddresses.length,
                  itemBuilder: (context, index) {
                    final address = _savedAddresses[index];
                    final isSelected = _selectedAddress?['id'] == address['id'];

                    return _buildAddressItem(address, isSelected, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressItem(
      Map<String, dynamic> address, bool isSelected, int index) {
    final isDark = isDarkModeNotifier.value;
    final addressData = address['address'] as Map<String, dynamic>;
    final landmark = (addressData['landmark'] != null &&
            (addressData['landmark'] as String).isNotEmpty)
        ? '${addressData['landmark']}, '
        : '';
    final fullAddress =
        '${addressData['building'] ?? ''}, ${addressData['area'] ?? ''}, $landmark${addressData['city'] ?? ''}, ${addressData['state'] ?? ''} - ${addressData['pincode'] ?? ''}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddress = address;
          _userName = address['fullName'];
          _userEmail = address['email'];
          _userMobile = address['mobile'];
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBB694A)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFBB694A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                address['isMainProfile'] ? Icons.home : Icons.location_on,
                color: const Color(0xFFBB694A),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Address details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and badges row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address['fullName'],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB694A).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFBB694A)
                                .withOpacity(isSelected ? 1 : 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isSelected
                              ? 'Selected'
                              : (address['addressType'] ?? 'HOME'),
                          style: const TextStyle(
                            color: Color(0xFFBB694A),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fullAddress,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!address['isMainProfile'])
              GestureDetector(
                onTap: () => _showDeleteDialog(address),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> address) {
    final isDark = isDarkModeNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Address',
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(address);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    try {
      final user = _auth.currentUser;
      if (user != null && !address['isMainProfile']) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('saved_addresses')
            .doc(address['id'])
            .delete();

        // Remove from local list
        setState(() {
          _savedAddresses.removeWhere((addr) => addr['id'] == address['id']);

          // If deleted address was selected, select the first available address
          if (_selectedAddress?['id'] == address['id'] &&
              _savedAddresses.isNotEmpty) {
            _selectedAddress = _savedAddresses.first;
            _userName = _selectedAddress!['fullName'];
            _userEmail = _selectedAddress!['email'];
            _userMobile = _selectedAddress!['mobile'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Color(0xFFBB694A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToNewAddress() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NewAddressScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((result) {
      // Only reload addresses if a new address was actually added
      if (result == true) {
        _loadUserAddresses(preserveSelection: true);
      }
      // If result is null or false, don't reload to preserve current selection
    });
  }

  double _calculateSubtotal() {
    double total = 0;
    for (var item in widget.items) {
      double price =
          double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  double _calculateTax() {
    return 0.0;
  }

  double _calculateShipping() {
    return 0.0;
  }

  double _calculateGrandTotal() {
    double total =
        _calculateSubtotal() + _calculateTax() + _calculateShipping();
    if (_appliedCoupon != null) {
      double discountValue = (_appliedCoupon!['value'] ?? 0).toDouble();
      if (_appliedCoupon!['discountType'] == 'percentage') {
        total -= (total * discountValue) / 100;
      } else {
        total -= discountValue;
      }
    }
    return total > 0 ? total : 0;
  }

  double _getDiscountAmount() {
    if (_appliedCoupon == null) return 0;
    double discountValue = (_appliedCoupon!['value'] ?? 0).toDouble();
    if (_appliedCoupon!['discountType'] == 'percentage') {
      return (_calculateSubtotal() * discountValue) / 100;
    } else {
      return discountValue;
    }
  }

  int _getTotalItems() {
    return widget.items
        .fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  Future<void> _validateAndApplyCoupon(String couponCode) async {
    if (couponCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
    });

    try {
      final couponSnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .limit(1)
          .get();

      if (couponSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid coupon code'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isValidatingCoupon = false;
        });
        return;
      }

      final couponData = couponSnapshot.docs.first.data();

      // Check if coupon is active
      if (!(couponData['isActive'] ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon code Expired'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isValidatingCoupon = false;
        });
        return;
      }

      // Coupon is valid and active
      setState(() {
        _appliedCoupon = couponData;
        _promoCode = couponCode.toUpperCase();
        _isValidatingCoupon = false;
      });

      _promoCodeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon code applied successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error validating coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error validating coupon code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _promoCode = '';
      _promoCodeController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coupon code removed'),
        backgroundColor: Color(0xFFBB694A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Razorpay Payment Methods
  void _openRazorpayCheckout() {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    var options = {
      'key': 'rzp_test_RB4Zp3Z8ZOVtU4', // Your test key
      'amount': (_calculateGrandTotal() * 100).toInt(), // Amount in paise
      'name': 'Beinn',
      'description': 'Order Payment for ${_getTotalItems()} items',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': '+91$_userMobile',
        'email': _userEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      // ignore: avoid_print
      print('Error opening Razorpay: $e');
      setState(() {
        _isProcessingPayment = false;
      });
      _showErrorDialog(
          'Payment Error', 'Failed to open payment gateway. Please try again.');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    _navigateToOrderPlaced(
        response.paymentId!, response.orderId, response.signature);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    _showErrorDialog('Payment Failed',
        response.message ?? 'Payment was unsuccessful. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: const Color(0xFFBB694A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentMethodDialog() {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = isDarkModeNotifier.value;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        title: Text(
          'Select Payment Method',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How would you like to pay?',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Pay Online Option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedPaymentMethod = 'online';
                });
                _openRazorpayCheckout();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFBB694A).withOpacity(0.3),
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBB694A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Color(0xFFBB694A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay Online',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Card, UPI, Wallet, NetBanking',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDark ? Colors.grey[400] : Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cash on Delivery Option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedPaymentMethod = 'cod';
                });
                _processCashOnDelivery();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFBB694A).withOpacity(0.3),
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBB694A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Color(0xFFBB694A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash on Delivery',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pay when your order arrives',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDark ? Colors.grey[400] : Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _processCashOnDelivery() {
    if (_selectedAddress == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final totalAmount = _calculateGrandTotal().toStringAsFixed(0);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Color(0xFFBB694A).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_shipping, color: Color(0xFFBB694A), size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Confirm COD Order', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to proceed with Cash on Delivery for this order?',
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 16),
              Container(
                 padding: EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Color(0xFFBB694A).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFBB694A).withOpacity(0.3))),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Icon(Icons.info_outline, color: Color(0xFFBB694A), size: 20),
                     SizedBox(width: 12),
                     Expanded(child: Text('Kindly keep ₹$totalAmount ready to hand over to the delivery executive at the time of delivery.', style: TextStyle(color: isDark ? Colors.grey[200] : Colors.grey[800], fontSize: 13, height: 1.4, fontWeight: FontWeight.w500))),
                   ],
                 ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeCODOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFBB694A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Place Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _executeCODOrder() {
    // Generate order number
    final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Prepare order data for Cash on Delivery
    final orderData = {
      'orderNumber': orderNumber,
      'customerInfo': {
        'name': _userName,
        'email': _userEmail,
        'mobile': '+91$_userMobile',
      },
      'deliveryAddress': {
        'fullName': _selectedAddress!['fullName'],
        'address': _selectedAddress!['address'],
        'addressType': _selectedAddress!['addressType'],
      },
      'items': widget.items,
      'pricing': {
        'subtotal': _calculateSubtotal(),
        'tax': _calculateTax(),
        'shipping': _calculateShipping(),
        'grandTotal': _calculateGrandTotal(),
        'totalItems': _getTotalItems(),
        'coupon': _appliedCoupon != null
            ? {
                'code': _promoCode,
                'value': _appliedCoupon!['value'],
                'discountType': _appliedCoupon!['discountType'],
                'discountAmount': _getDiscountAmount(),
              }
            : null,
      },
      'payment': {
        'paymentId': 'COD_${DateTime.now().millisecondsSinceEpoch}',
        'razorpayOrderId': null,
        'signature': null,
        'method': 'cash_on_delivery',
        'status': 'pending',
        'amount': _calculateGrandTotal(),
      },
      'orderDate': DateTime.now(),
      'estimatedDelivery': DateTime.now().add(const Duration(days: 7)),
    };

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderPlacedScreen(orderData: orderData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToOrderPlaced(
      String paymentId, String? orderId, String? signature) {
    // Generate order number
    final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Prepare order data
    final orderData = {
      'orderNumber': orderNumber,
      'customerInfo': {
        'name': _userName,
        'email': _userEmail,
        'mobile': '+91$_userMobile',
      },
      'deliveryAddress': {
        'fullName': _selectedAddress!['fullName'],
        'address': _selectedAddress!['address'],
        'addressType': _selectedAddress!['addressType'],
      },
      'items': widget.items,
      'pricing': {
        'subtotal': _calculateSubtotal(),
        'tax': _calculateTax(),
        'shipping': _calculateShipping(),
        'grandTotal': _calculateGrandTotal(),
        'totalItems': _getTotalItems(),
        'coupon': _appliedCoupon != null
            ? {
                'code': _promoCode,
                'value': _appliedCoupon!['value'],
                'discountType': _appliedCoupon!['discountType'],
                'discountAmount': _getDiscountAmount(),
              }
            : null,
      },
      'payment': {
        'paymentId': paymentId,
        'razorpayOrderId': orderId,
        'signature': signature,
        'method': 'razorpay',
        'status': 'completed',
        'amount': _calculateGrandTotal(),
      },
      'orderDate': DateTime.now(),
      'estimatedDelivery': DateTime.now().add(const Duration(days: 7)),
    };

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderPlacedScreen(orderData: orderData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    final isDark = isDarkModeNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFBB694A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateItemTotal(Map<String, dynamic> item) {
    final price =
        double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
    final quantity = item['quantity'] ?? 1;
    return price * quantity;
  }

  Widget _buildDeliveryAddress(bool isDark) {
    if (_isLoadingAddress) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Color(0xFFBB694A),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading address...',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedAddress == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              'No delivery address found',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Please add an address to continue',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final addressData = _selectedAddress!['address'] as Map<String, dynamic>;
    final landmark = (addressData['landmark'] != null &&
            (addressData['landmark'] as String).isNotEmpty)
        ? '${addressData['landmark']}, '
        : '';
    final fullAddress =
        '${addressData['building'] ?? ''}, ${addressData['area'] ?? ''}, $landmark${addressData['city'] ?? ''}, ${addressData['state'] ?? ''} - ${addressData['pincode'] ?? ''}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFFBB694A),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Deliver to:',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  _userName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBB694A).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFBB694A).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _selectedAddress!['addressType'] ?? 'HOME',
                  style: const TextStyle(
                    color: Color(0xFFBB694A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fullAddress,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (_userMobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFFBB694A),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '+91 $_userMobile',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (_userEmail.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFBB694A),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _userEmail,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              height: 1,
              thickness: 1),
          const SizedBox(height: 12),
          // Address action buttons
          Row(
            children: [
              // Change button
              Expanded(
                child: GestureDetector(
                  onTap: _showAddressSelectionModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFBB694A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          color: Color(0xFFBB694A),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Color(0xFFBB694A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add New button
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToNewAddress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBB694A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFBB694A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, bool isDark) {
    final price =
        double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
    final quantity = item['quantity'] ?? 1;
    final totalItemPrice = price * quantity;

    final String img = (item['image'] ?? '').toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'checkout_item_${item['id']}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                image: img.isNotEmpty
                    ? DecorationImage(
                        image: img.startsWith('assets/')
                            ? AssetImage(img) as ImageProvider
                            : NetworkImage(img),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: img.isEmpty
                  ? Icon(Icons.image,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item['selectedSize'] != null &&
                    item['selectedColor'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['category'] == 'Perfumes'
                          ? 'Type: ${item['selectedColor']}'
                          : 'Size: ${item['selectedSize']} | Color: ${item['selectedColor']}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${totalItemPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFBB694A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBB694A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFBB694A).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: const TextStyle(
                          color: Color(0xFFBB694A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer,
                color: Color(0xFFBB694A),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Promo Code',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedCoupon != null)
            // Show applied coupon chip
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: $_promoCode',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Discount: ₹${_getDiscountAmount().toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.green[400]
                                  : Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _removeCoupon,
                      child: Icon(
                        Icons.close,
                        color: Colors.green[600],
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Show input field for coupon
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _promoCodeController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      enabled: !_isValidatingCoupon,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isValidatingCoupon
                      ? null
                      : () {
                          if (_promoCodeController.text.isNotEmpty) {
                            _validateAndApplyCoupon(_promoCodeController.text);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isValidatingCoupon
                          ? Colors.grey[700]
                          : const Color(0xFFBB694A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isValidatingCoupon
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            'Optional: Enter a valid promo code to get discount',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Color(0xFFBB694A),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Price Details',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Subtotal (${_getTotalItems()} items)',
              '₹${_calculateSubtotal().toStringAsFixed(0)}', isDark),

          _buildPriceRow(
            'Shipping',
            _calculateShipping() == 0
                ? 'FREE'
                : '₹${_calculateShipping().toStringAsFixed(0)}',
            isDark,
            isShipping: true,
          ),
          if (_appliedCoupon != null) ...[
            _buildPriceRow(
              'Discount (${'${_appliedCoupon!['discountType'] == 'percentage' ? '${_appliedCoupon!['value']}%' : ''}'})',
              '-₹${_getDiscountAmount().toStringAsFixed(0)}',
              isDark,
              isDiscount: true,
            ),
          ],
          Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              height: 22,
              thickness: 1),
          _buildPriceRow(
            'Total Amount',
            '₹${_calculateGrandTotal().toStringAsFixed(0)}',
            isDark,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDark,
      {bool isTotal = false,
      bool isShipping = false,
      bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDiscount
                  ? Colors.green
                  : (isTotal
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey[600])),
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Row(
            children: [
              if (isShipping && value == 'FREE')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (!(isShipping && value == 'FREE'))
                Text(
                  value,
                  style: TextStyle(
                    color: isDiscount
                        ? Colors.green
                        : (isTotal
                            ? const Color(0xFFBB694A)
                            : (isDark ? Colors.white : Colors.black)),
                    fontSize: isTotal ? 15 : 13,
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price summary in bottom bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_calculateGrandTotal().toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFBB694A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isProcessingPayment ? null : _showPaymentMethodDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isProcessingPayment
                          ? Colors.grey[700]
                          : const Color(0xFFBB694A),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    margin: const EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isProcessingPayment)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isProcessingPayment
                              ? 'Processing...'
                              : 'Place Order',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
          return WillPopScope(
            onWillPop: () async {
              if (_isProcessingPayment) {
                return false;
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: isDark ? Colors.black : const Color(0xFFFAF9F5),
              appBar: AppBar(
                backgroundColor:
                    isDark ? Colors.black : const Color(0xFFFAF9F5),
                elevation: 0,
                leading: Center(
                  child: GestureDetector(
                    onTap: _isProcessingPayment
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: _isProcessingPayment
                            ? Colors.grey[600]
                            : (isDark ? Colors.white : Colors.black),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Color(0xFFBB694A),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titleSpacing: 8,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Delivery Address Section
                            SlideTransition(
                              position: _slideAnimation,
                              child: _buildDeliveryAddress(isDark),
                            ),
                            const SizedBox(height: 20),
                            // Order Summary
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: const Interval(0.1, 0.6,
                                    curve: Curves.easeOutCubic),
                              )),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[300]!,
                                      width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart,
                                          color: Color(0xFFBB694A),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Order Summary',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF3E2723)
                                            : const Color(0xFFFFF3E0),
                                        border: Border.all(
                                          color: const Color(0xFFBB694A),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.info_outline_rounded,
                                                  color: Color(0xFFBB694A),
                                                  size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                "IMPORTANT NOTE",
                                                style: TextStyle(
                                                  color: Color(0xFFBB694A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "At Beinn, we work closely with our manufacturing partners to deliver premium clothing.\nIn rare cases, certain sizes or colors may go out of stock after an order is placed.\nIf this happens, our support team will reach out to you within 24 hours to confirm availability, suggest alternatives, or arrange a refund.\nHappy Shopping ☺️",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[200]
                                                  : Colors.black87,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...widget.items
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      int index = entry.key;
                                      Map<String, dynamic> item = entry.value;
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: _slideController,
                                          curve: Interval(
                                            0.2 + (index * 0.1),
                                            0.8,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        )),
                                        child: _buildOrderItem(item, isDark),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: const Interval(0.15, 0.7,
                                    curve: Curves.easeOutCubic),
                              )),
                              child: _buildPromoCodeSection(isDark),
                            ),
                            const SizedBox(height: 20),
                            // Price Breakdown
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 1.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: const Interval(0.3, 0.8,
                                    curve: Curves.easeOutCubic),
                              )),
                              child: _buildPriceBreakdown(isDark),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomSection(isDark),
            ),
          );
        });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _modalController.dispose();
    _promoCodeController.dispose();
    _razorpay.clear();
    super.dispose();
  }
}

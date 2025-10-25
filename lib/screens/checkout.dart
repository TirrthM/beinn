import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'new_address.dart';
import 'order_placed.dart';

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
              orElse: () =>
              allAddresses.isNotEmpty ? allAddresses.first : {},
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
    return AnimatedBuilder(
      animation: _modalAnimation,
      builder: (context, child) {
        _modalController.forward();
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Select delivery address',
                      style: TextStyle(
                        color: Color(0xFFD2691E),
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
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Saved addresses header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saved addresses',
                    style: TextStyle(
                        color: Colors.white,
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
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD2691E) : Colors.grey[800]!,
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
                color: const Color(0xFFD2691E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                address['isMainProfile'] ? Icons.home : Icons.location_on,
                color: const Color(0xFFD2691E),
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
                          style: const TextStyle(
                            color: Colors.white,
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
                          color: const Color(0xFFD2691E).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFD2691E)
                                .withOpacity(isSelected ? 1 : 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isSelected
                              ? 'Selected'
                              : (address['addressType'] ?? 'HOME'),
                          style: const TextStyle(
                            color: Color(0xFFD2691E),
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
                      color: Colors.grey[300],
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
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Address',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
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
            backgroundColor: Color(0xFFD2691E),
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
        // FIX: removed 'const' to avoid "constructor isn't const" error
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
    return _calculateSubtotal() * 0.18; // 18% GST
  }

  double _calculateShipping() {
    return _calculateSubtotal() > 1000 ? 0 : 50; // Free shipping above ₹1000
  }

  double _calculateGrandTotal() {
    return _calculateSubtotal() + _calculateTax() + _calculateShipping();
  }

  int _getTotalItems() {
    return widget.items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
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
      _showErrorDialog('Payment Error',
          'Failed to open payment gateway. Please try again.');
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
        backgroundColor: const Color(0xFFD2691E),
        behavior: SnackBarBehavior.floating,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFD2691E),
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
    final qty = item['quantity'] ?? 1;
    return price * qty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header (compact)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Checkout',
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Delivery Address Section
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.0, 0.4,
                                curve: Curves.easeOutCubic),
                          )),
                          child: _buildDeliveryAddress(),
                        ),
                        const SizedBox(height: 20),
                        // Order Items
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.1, 0.5,
                                curve: Curves.easeOutCubic),
                          )),
                          child: const Text(
                            'Order Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.items.asMap().entries.map((entry) {
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
                            child: _buildOrderItem(item),
                          );
                        }).toList(),
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
                          child: _buildPriceBreakdown(),
                        ),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                ),
                // Bottom Section
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    if (_isLoadingAddress) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                color: Color(0xFFD2691E),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading address...',
              style: TextStyle(
                color: Colors.grey[400],
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
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.grey[500],
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              'No delivery address found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Please add an address to continue',
              style: TextStyle(
                color: Colors.grey[500],
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
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.location_on,
                color: Color(0xFFD2691E),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Deliver to:',
                style: TextStyle(
                  color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD2691E).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _selectedAddress!['addressType'] ?? 'HOME',
                  style: const TextStyle(
                    color: Color(0xFFD2691E),
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
              color: Colors.grey[300],
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
                  color: Color(0xFFD2691E),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '+91 $_userMobile',
                  style: const TextStyle(
                    color: Colors.white,
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
                  color: Color(0xFFD2691E),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[800], height: 1, thickness: 1),
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
                        color: const Color(0xFFD2691E),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          color: Color(0xFFD2691E),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Color(0xFFD2691E),
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
                      color: const Color(0xFFD2691E),
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildOrderItem(Map<String, dynamic> item) {
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
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
                color: Colors.grey[800],
                image: img.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(img),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: img.isEmpty
                  ? Icon(Icons.image, color: Colors.grey[500], size: 20)
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
                  style: const TextStyle(
                    color: Colors.white,
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
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Size: ${item['selectedSize']} | Color: ${item['selectedColor']}',
                      style: TextStyle(
                        color: Colors.grey[300],
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
                        color: Color(0xFFD2691E),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2691E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD2691E).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: const TextStyle(
                          color: Color(0xFFD2691E),
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

  Widget _buildPriceBreakdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.receipt_long,
                color: Color(0xFFD2691E),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Price Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Subtotal (${_getTotalItems()} items)',
              '₹${_calculateSubtotal().toStringAsFixed(0)}'),
          _buildPriceRow(
              'Tax (GST 18%)', '₹${_calculateTax().toStringAsFixed(0)}'),
          _buildPriceRow(
            'Shipping',
            _calculateShipping() == 0
                ? 'FREE'
                : '₹${_calculateShipping().toStringAsFixed(0)}',
            isShipping: true,
          ),
          Divider(color: Colors.grey[800], height: 22, thickness: 1),
          _buildPriceRow(
            'Total Amount',
            '₹${_calculateGrandTotal().toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isTotal = false, bool isShipping = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey[400],
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
                    color: isTotal ? const Color(0xFFD2691E) : Colors.white,
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

  Widget _buildBottomSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Total Amount Section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_calculateGrandTotal().toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFD2691E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_getTotalItems()} items',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Place Order Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                _isProcessingPayment ? null : _openRazorpayCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2691E),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0xFFD2691E).withOpacity(0.25),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Place Order',
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _modalController.dispose();
    _razorpay.clear(); // Clear Razorpay instance
    super.dispose();
  }
}

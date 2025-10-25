import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'invoice.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _orderDetails;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Extended thank you messages (25 total) - same as order_placed.dart
  final List<String> _thankYouMessages = [
    "Your style journey begins now! ✨",
    "Fashion dreams delivered to your doorstep! 🌟",
    "You've made an excellent choice! 💫",
    "Style is calling, and you answered perfectly! 🎯",
    "Your wardrobe is about to get a major upgrade! 🔥",
    "Thank you for choosing quality and style! 💎",
    "Your fashion sense is impeccable! 👑",
    "Style meets comfort - the perfect combination! 🌈",
    "You're about to look absolutely stunning! ✨",
    "Fashion forward thinking - we love it! 🚀",
    "Your style story continues with us! 📖",
    "Elegance is on its way to you! 🌸",
    "You've unlocked premium fashion! 🔓",
    "Style delivered with love and care! 💝",
    "Your confidence boost is being packaged! 💪",
    "Fashion magic is heading your way! 🎭",
    "You deserve nothing but the best! 👌",
    "Style that speaks your language! 🗣️",
    "Your fashion adventure starts here! 🗺️",
    "Trendsetter alert - that's you! 📢",
    "Elevating your wardrobe game to the next level! 🎮",
    "Premium quality meets unbeatable style! 🏆",
    "Your personal fashion revolution starts today! 🌟",
    "Crafted with passion, delivered with pride! 🎨",
    "Welcome to the world of limitless style possibilities! 🌍"
  ];

  @override
  void initState() {
    super.initState();
    print('🔍 OrderDetailsScreen initState called for order: ${widget.order['orderNumber']}');

    // Use the data passed from the previous screen initially
    _orderDetails = widget.order;

    _initializeAnimations();

    // Optionally fetch fresh data from Firestore (but don't show loading since we have data)
    _fetchLatestOrderDetails();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _bounceController.forward();
  }

  // Fetch latest data from Firestore (background update)
  Future<void> _fetchLatestOrderDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('🔍 Fetching latest order details for: ${widget.order['orderNumber']}');

        final orderDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(widget.order['orderNumber'])
            .get();

        if (orderDoc.exists) {
          final data = orderDoc.data()!;
          print('✅ Latest order data fetched successfully');

          // Create updated order object
          Map<String, dynamic> updatedOrderDetails = {
            'id': orderDoc.id,
            'orderNumber': data['orderNumber'] ?? orderDoc.id,
            'status': data['status'] ?? 'order_placed',
            'isRated': data['isRated'] ?? false,
            'rating': data['rating'],
            'review': data['review'],
            'ratedAt': data['ratedAt'],
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          };

          // Handle dates
          if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
            updatedOrderDetails['orderDate'] = (data['orderDate'] as Timestamp).toDate();
          } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            updatedOrderDetails['orderDate'] = (data['createdAt'] as Timestamp).toDate();
          } else {
            updatedOrderDetails['orderDate'] = DateTime.now();
          }

          if (data['estimatedDelivery'] != null && data['estimatedDelivery'] is Timestamp) {
            updatedOrderDetails['estimatedDelivery'] = (data['estimatedDelivery'] as Timestamp).toDate();
          } else {
            // Updated to add 9 days from order date
            updatedOrderDetails['estimatedDelivery'] = (updatedOrderDetails['orderDate'] as DateTime).add(Duration(days: 9));
          }

          // Handle other data
          updatedOrderDetails['customerInfo'] = data['customerInfo'] ?? {};
          updatedOrderDetails['deliveryAddress'] = data['deliveryAddress'] ?? {};
          updatedOrderDetails['items'] = data['items'] ?? [];
          updatedOrderDetails['pricing'] = data['pricing'] ?? {};
          updatedOrderDetails['payment'] = data['payment'] ?? {};

          // Update state with fresh data
          if (mounted) {
            setState(() {
              _orderDetails = updatedOrderDetails;
            });
          }
        }
      }
    } catch (e) {
      print('⚠️ Error fetching latest order details: $e');
      // Don't show error since we have existing data
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _getUniqueThankYouMessage() {
    final orderNumber = _orderDetails?['orderNumber']?.toString() ?? '';
    final seed = orderNumber.hashCode;
    final random = Random(seed);
    return _thankYouMessages[random.nextInt(_thankYouMessages.length)];
  }

  // Helper function to format address from Map to String
  String _formatAddress(dynamic addressData) {
    if (addressData is String) {
      return addressData;
    } else if (addressData is Map<String, dynamic>) {
      final building = addressData['building'] ?? '';
      final area = addressData['area'] ?? '';
      final landmark = addressData['landmark'] ?? '';
      final city = addressData['city'] ?? '';
      final state = addressData['state'] ?? '';
      final pincode = addressData['pincode'] ?? '';

      String formattedAddress = '';
      if (building.isNotEmpty) formattedAddress += '$building, ';
      if (area.isNotEmpty) formattedAddress += '$area, ';
      if (landmark.isNotEmpty) formattedAddress += '$landmark, ';
      if (city.isNotEmpty) formattedAddress += '$city, ';
      if (state.isNotEmpty) formattedAddress += '$state';
      if (pincode.isNotEmpty) formattedAddress += ' - $pincode';

      return formattedAddress.isNotEmpty ? formattedAddress : 'Address not available';
    }
    return 'Address not available';
  }

  // Helper function to get individual item price
  double _getItemPrice(Map<String, dynamic> item) {
    if (item['price'] != null) {
      String priceString = item['price'].toString();
      String cleanPrice = priceString.replaceAll('₹', '').replaceAll(',', '').trim();
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  // Generate Invoice function - similar to order_placed.dart
  void _generateInvoice() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFD2691E)),
            SizedBox(width: 16),
            Text(
              'Generating invoice...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final invoiceService = InvoiceService();
      await invoiceService.generateInvoice(_orderDetails!);

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Invoice downloaded successfully to Downloads folder!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to generate invoice. Please try again.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 3),
        ),
      );
      print('Invoice generation error: $e');
    }
  }

  void _rateOrder() async {
    int selectedRating = 0;
    TextEditingController reviewController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Rate Your Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'How was your shopping experience?',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) =>
                    GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          selectedRating > index ? Icons.star : Icons.star_border,
                          color: Color(0xFFD2691E),
                          size: 40,
                        ),
                      ),
                    ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: reviewController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write your review (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[600]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedRating > 0 ? () async {
                        await _saveRatingToFirestore(selectedRating, reviewController.text.trim());
                        Navigator.pop(context);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD2691E),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Submit Rating',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRatingToFirestore(int rating, String review) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('💾 Saving rating for order: ${_orderDetails!['orderNumber']}');

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(_orderDetails!['orderNumber'])
            .update({
          'isRated': true,
          'rating': rating,
          'review': review.isNotEmpty ? review : null,
          'ratedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Rating saved successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Thank you for rating us $rating stars!'),
                ],
              ),
              backgroundColor: Color(0xFFD2691E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }

        // Update local state
        setState(() {
          _orderDetails!['isRated'] = true;
          _orderDetails!['rating'] = rating;
          _orderDetails!['review'] = review.isNotEmpty ? review : null;
        });
      }
    } catch (e) {
      print('❌ Error saving rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rating. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  double safeToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int safeToInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
                // Header - Updated with working Invoice button
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Order Details',
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: _generateInvoice,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFFD2691E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Color(0xFFD2691E).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFFD2691E),
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Invoice',
                                  style: TextStyle(
                                    color: Color(0xFFD2691E),
                                    fontSize: 12,
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
                ),

                // Content
                Expanded(
                  child: _buildContent(),
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

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFD2691E),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading order details...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            SizedBox(height: 20),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _fetchLatestOrderDetails();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD2691E),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_orderDetails == null) {
      return Center(
        child: Text(
          'No order details found',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thank You Message
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.1, 0.5, curve: Curves.easeOutCubic),
            )),
            child: _buildUniqueThankYouMessage(),
          ),
          SizedBox(height: 24),

          // Order Information - Updated with Order ID
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.15, 0.55, curve: Curves.easeOutCubic),
            )),
            child: _buildOrderInformation(),
          ),
          SizedBox(height: 24),

          // Delivery Address
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.2, 0.6, curve: Curves.easeOutCubic),
            )),
            child: _buildDeliveryAddress(),
          ),
          SizedBox(height: 24),

          // Order Summary
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.3, 0.7, curve: Curves.easeOutCubic),
            )),
            child: Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order Items
          ..._buildOrderItems(),
          SizedBox(height: 24),

          // Price Details
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.5, 0.9, curve: Curves.easeOutCubic),
            )),
            child: _buildPriceDetails(),
          ),
          SizedBox(height: 24),

          // Payment Information
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
            )),
            child: _buildPaymentInfo(),
          ),
          SizedBox(height: 24),

          // Need Help
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(0.7, 1.0, curve: Curves.easeOutCubic),
            )),
            child: _buildNeedHelp(),
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUniqueThankYouMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD2691E).withOpacity(0.15),
            Color(0xFFD2691E).withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFD2691E).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFD2691E),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFD2691E).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFD2691E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _getUniqueThankYouMessage(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'We\'re thrilled to be part of your style journey!',
            style: TextStyle(
              color: Color(0xFFD2691E).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformation() {
    final orderDate = _orderDetails!['orderDate'] as DateTime;
    // Updated estimated delivery to 9 days from order date
    final estimatedDelivery = _orderDetails!['estimatedDelivery'] as DateTime? ?? orderDate.add(Duration(days: 9));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFD2691E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Order Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Order ID Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFD2691E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFD2691E).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFD2691E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_outlined,
                    color: Color(0xFFD2691E),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '#${_orderDetails!['orderNumber']}',
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Confirmed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_formatDate(orderDate)} at ${_formatTime(orderDate)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFD2691E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFD2691E).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFD2691E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFFD2691E),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(estimatedDelivery),
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Delivery time may vary based on location and weather conditions.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    final customerInfo = _orderDetails!['customerInfo'] as Map<String, dynamic>;
    final deliveryAddress = _orderDetails!['deliveryAddress'] as Map<String, dynamic>;

    // Format the address properly
    final formattedAddress = _formatAddress(deliveryAddress['address']);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Color(0xFFD2691E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                deliveryAddress['fullName'] ?? customerInfo['name'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFD2691E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(0xFFD2691E).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  deliveryAddress['addressType'] ?? 'HOME',
                  style: TextStyle(
                    color: Color(0xFFD2691E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            formattedAddress,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: Color(0xFFD2691E),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Mobile: ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                customerInfo['mobile'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: Color(0xFFD2691E),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Email: ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  customerInfo['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems() {
    final items = _orderDetails!['items'] as List<dynamic>;
    return items.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> item = entry.value;
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            0.4 + (index * 0.1),
            0.8,
            curve: Curves.easeOutCubic,
          ),
        )),
        child: _buildOrderItem(item),
      );
    }).toList();
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final quantity = safeToInt(item['quantity'] ?? 1);
    final price = _getItemPrice(item);
    final totalPrice = price * quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item['image'] != null
                  ? DecorationImage(
                image: NetworkImage(item['image']),
                fit: BoxFit.cover,
              )
                  : null,
              color: item['image'] == null ? Colors.grey[700] : null,
            ),
            child: item['image'] == null
                ? Icon(Icons.image, color: Colors.grey[500], size: 20)
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                if (item['selectedSize'] != null && item['selectedColor'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Color(0xFFD2691E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFD2691E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFD2691E).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontSize: 12,
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

  Widget _buildPriceDetails() {
    final pricing = _orderDetails!['pricing'] as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Color(0xFFD2691E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Price Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildPriceRow('Subtotal (${safeToInt(pricing['totalItems'])} items)', '₹${safeToDouble(pricing['subtotal']).toStringAsFixed(0)}'),
          _buildPriceRow('Tax (GST 18%)', '₹${safeToDouble(pricing['tax']).toStringAsFixed(0)}'),
          _buildPriceRow(
            'Shipping',
            safeToDouble(pricing['shipping']) == 0 ? 'FREE' : '₹${safeToDouble(pricing['shipping']).toStringAsFixed(0)}',
            isShipping: true,
          ),
          Divider(color: Colors.grey[700], height: 24, thickness: 1),
          _buildPriceRow(
            'Total Amount',
            '₹${safeToDouble(pricing['grandTotal']).toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isShipping = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey[400],
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isShipping && value == 'FREE')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FREE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: isTotal ? Color(0xFFD2691E) : Colors.white,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final payment = _orderDetails!['payment'] as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: Color(0xFFD2691E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Payment Method: ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Text(
                payment['method'] ?? 'Razorpay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Payment ID: ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  payment['paymentId'] ?? 'N/A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Status: ',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment['status'] ?? 'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelp() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Color(0xFFD2691E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Need Help?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Our customer support team is here to help you with any questions about your order.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Color(0xFFD2691E),
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Email Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'support@beinn.com',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: Color(0xFFD2691E),
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Phone Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '+91 9876543210',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
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
    );
  }

  Widget _buildBottomSection() {
    final hasRating = _orderDetails?['isRated'] == true;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFD2691E), width: 2),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD2691E),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Shop More',
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
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: hasRating ? null : _rateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasRating ? Colors.grey[600] : Color(0xFFD2691E),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: hasRating ? 0 : 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasRating ? Icons.star : Icons.star_rate,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      hasRating ? 'Rated' : 'Rate Order',
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
    _bounceController.dispose();
    super.dispose();
  }
}

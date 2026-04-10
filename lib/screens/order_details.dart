import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'invoice.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
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
    "Your fashion sense is impeccable! 👗",
    "Style meets comfort - the perfect combination! 🌈",
    "You're about to look absolutely stunning! ✨",
    "Fashion forward thinking - we love it! 🚀",
    "Your style story continues with us! 📖",
    "Elegance is on its way to you! 🌸",
    "You've unlocked premium fashion! 🏆",
    "Style delivered with love and care! 💖",
    "Your confidence boost is being packaged! 💪",
    "Fashion magic is heading your way! 🎭",
    "You deserve nothing but the best! 👌",
    "Style that speaks your language! 🗣️",
    "Your fashion adventure starts here! 🗺️",
    "Trendsetter alert - that's you! 📣",
    "Elevating your wardrobe game to the next level! 🎮",
    "Premium quality meets unbeatable style! 🏅",
    "Your personal fashion revolution starts today! 🌟",
    "Crafted with passion, delivered with pride! 🎨",
    "Welcome to the world of limitless style possibilities! 🌍"
  ];

  @override
  void initState() {
    super.initState();
    print(
        'ðŸ” OrderDetailsScreen initState called for order: ${widget.order['orderNumber']}');

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
        print(
            'ðŸ” Fetching latest order details for: ${widget.order['orderNumber']}');

        final orderDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(widget.order['orderNumber'])
            .get();

        if (orderDoc.exists) {
          final data = orderDoc.data()!;
          print('âœ… Latest order data fetched successfully');

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
            updatedOrderDetails['orderDate'] =
                (data['orderDate'] as Timestamp).toDate();
          } else if (data['createdAt'] != null &&
              data['createdAt'] is Timestamp) {
            updatedOrderDetails['orderDate'] =
                (data['createdAt'] as Timestamp).toDate();
          } else {
            updatedOrderDetails['orderDate'] = DateTime.now();
          }

          if (data['estimatedDelivery'] != null &&
              data['estimatedDelivery'] is Timestamp) {
            updatedOrderDetails['estimatedDelivery'] =
                (data['estimatedDelivery'] as Timestamp).toDate();
          } else {
            // Updated to add 9 days from order date
            updatedOrderDetails['estimatedDelivery'] =
                (updatedOrderDetails['orderDate'] as DateTime)
                    .add(Duration(days: 9));
          }

          // Handle other data
          updatedOrderDetails['customerInfo'] = data['customerInfo'] ?? {};
          updatedOrderDetails['deliveryAddress'] =
              data['deliveryAddress'] ?? {};
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
      print('âš ï¸ Error fetching latest order details: $e');
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

      return formattedAddress.isNotEmpty
          ? formattedAddress
          : 'Address not available';
    }
    return 'Address not available';
  }

  // Helper function to get individual item price
  double _getItemPrice(Map<String, dynamic> item) {
    if (item['price'] != null) {
      String priceString = item['price'].toString();
      String cleanPrice =
          priceString.replaceAll('\u20B9', '').replaceAll(',', '').trim();
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  // Generate Invoice function - similar to order_placed.dart
  void _generateInvoice() async {
    // Show loading indicator
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            content: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFFBB694A)),
                SizedBox(width: 16),
                Text(
                  'Generating invoice...',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
          );
        },
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
                child: Text(
                    'Invoice downloaded successfully to Downloads folder!'),
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
        builder: (context, setModalState) => ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, child) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Rate Your Order',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'How was your shopping experience?',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            selectedRating > index
                                ? Icons.star
                                : Icons.star_border,
                            color: Color(0xFFBB694A),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: reviewController,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Write your review (optional)',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
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
                            side: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[400]!),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedRating > 0
                              ? () async {
                                  await _saveRatingToFirestore(selectedRating,
                                      reviewController.text.trim());
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBB694A),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveRatingToFirestore(int rating, String review) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('ðŸ’¾ Saving rating for order: ${_orderDetails!['orderNumber']}');

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

        print('âœ… Rating saved successfully');

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
              backgroundColor: Color(0xFFBB694A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
      print('âŒ Error saving rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rating. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFFAF9F5),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isDark
                                        ? null
                                        : Border.all(
                                            color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Order Details',
                                style: TextStyle(
                                  color: Color(0xFFBB694A),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: _generateInvoice,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFBB694A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Color(0xFFBB694A).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFFBB694A),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Invoice',
                                        style: TextStyle(
                                          color: Color(0xFFBB694A),
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
                        child: _buildContent(isDark),
                      ),

                      // Bottom Section
                      _buildBottomSection(isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFBB694A),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading order details...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
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
                color: isDark ? Colors.white : Colors.black,
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
                backgroundColor: Color(0xFFBB694A),
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
            color: isDark ? Colors.white : Colors.black,
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
            child: _buildUniqueThankYouMessage(isDark),
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
            child: _buildOrderInformation(isDark),
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
            child: _buildDeliveryAddress(isDark),
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
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order Items
          ..._buildOrderItems(isDark),
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
            child: _buildPriceDetails(isDark),
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
            child: _buildPaymentInfo(isDark),
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
            child: _buildNeedHelp(isDark),
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUniqueThankYouMessage(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFBB694A).withOpacity(0.15),
            Color(0xFFBB694A).withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFBB694A).withOpacity(0.3),
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
                  color: Color(0xFFBB694A),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFBB694A).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFBB694A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _getUniqueThankYouMessage(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
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
              color: Color(0xFFBB694A).withOpacity(0.9),
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

  Widget _buildOrderInformation(bool isDark) {
    final orderDate = _orderDetails!['orderDate'] as DateTime;
    // Updated estimated delivery to 9 days from order date
    final estimatedDelivery =
        _orderDetails!['estimatedDelivery'] as DateTime? ??
            orderDate.add(Duration(days: 9));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFBB694A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Order Information',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
              color: Color(0xFFBB694A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Color(0xFFBB694A).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFBB694A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_outlined,
                    color: Color(0xFFBB694A),
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
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '#${_orderDetails!['orderNumber']}',
                        style: TextStyle(
                          color: Color(0xFFBB694A),
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
              color: isDark
                  ? Colors.grey[800]?.withOpacity(0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1),
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
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_formatDate(orderDate)} at ${_formatTime(orderDate)}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              color: Color(0xFFBB694A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Color(0xFFBB694A).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFBB694A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFFBB694A),
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
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(estimatedDelivery),
                        style: TextStyle(
                          color: Color(0xFFBB694A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Delivery time may vary based on location and weather conditions.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildDeliveryAddress(bool isDark) {
    final customerInfo = _orderDetails!['customerInfo'] as Map<String, dynamic>;
    final deliveryAddress =
        _orderDetails!['deliveryAddress'] as Map<String, dynamic>;

    // Format the address properly
    final formattedAddress = _formatAddress(deliveryAddress['address']);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Color(0xFFBB694A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFBB694A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(0xFFBB694A).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  deliveryAddress['addressType'] ?? 'HOME',
                  style: TextStyle(
                    color: Color(0xFFBB694A),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: Color(0xFFBB694A),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Mobile: ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                customerInfo['mobile'] ?? '',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                color: Color(0xFFBB694A),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Email: ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  customerInfo['email'] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
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

  List<Widget> _buildOrderItems(bool isDark) {
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
        child: _buildOrderItem(item, isDark),
      );
    }).toList();
  }

  Widget _buildOrderItem(Map<String, dynamic> item, bool isDark) {
    final quantity = safeToInt(item['quantity'] ?? 1);
    final price = _getItemPrice(item);
    final totalPrice = price * quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
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
                      image: item['image'].toString().startsWith('assets/')
                          ? AssetImage(item['image']) as ImageProvider
                          : NetworkImage(item['image']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: item['image'] == null
                  ? (isDark ? Colors.grey[700] : Colors.grey[300])
                  : null,
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
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                if (item['selectedSize'] != null &&
                    item['selectedColor'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['category'] == 'Perfumes'
                          ? 'Type: ${item['selectedColor']}'
                          : 'Size: ${item['selectedSize']} | Color: ${item['selectedColor']}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 10,
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\u20B9${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Color(0xFFBB694A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFBB694A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFBB694A).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          color: Color(0xFFBB694A),
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

  Widget _buildPriceDetails(bool isDark) {
    final pricing = _orderDetails!['pricing'] as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Color(0xFFBB694A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Price Details',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildPriceRow('Subtotal (${safeToInt(pricing['totalItems'])} items)',
              '\u20B9${safeToDouble(pricing['subtotal']).toStringAsFixed(0)}',
              isDark: isDark),

          _buildPriceRow(
            'Shipping',
            safeToDouble(pricing['shipping']) == 0
                ? 'FREE'
                : '\u20B9${safeToDouble(pricing['shipping']).toStringAsFixed(0)}',
            isShipping: true,
            isDark: isDark,
          ),
          Divider(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              height: 24,
              thickness: 1),
          _buildPriceRow(
            'Total Amount',
            '\u20B9${safeToDouble(pricing['grandTotal']).toStringAsFixed(0)}',
            isTotal: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isTotal = false, bool isShipping = false, required bool isDark}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
                color: isTotal
                    ? Color(0xFFBB694A)
                    : (isDark ? Colors.white : Colors.black),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(bool isDark) {
    final payment = _orderDetails!['payment'] as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: Color(0xFFBB694A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Information',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                payment['method'] ?? 'Razorpay',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  payment['paymentId'] ?? 'N/A',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildNeedHelp(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Color(0xFFBB694A),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Need Help?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'beinnlifestyle@gmail.com',
                query: 'subject=Support Request for Order ${widget.order['orderNumber'] ?? ''}',
              );
              try {
                await launchUrl(emailLaunchUri);
              } catch (e) {
                print('Could not launch email: $e');
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]?.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: Color(0xFFBB694A),
                    size: 28,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Email Support',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'beinnlifestyle@gmail.com',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    final hasRating = _orderDetails?['isRated'] == true;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
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
                  side: BorderSide(color: Color(0xFFBB694A), width: 2),
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
                      color: Color(0xFFBB694A),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Shop More',
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
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: hasRating ? null : _rateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasRating ? Colors.grey[600] : Color(0xFFBB694A),
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

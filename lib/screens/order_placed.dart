import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'invoice.dart';

class OrderPlacedScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderPlacedScreen({Key? key, required this.orderData}) : super(key: key);

  @override
  _OrderPlacedScreenState createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Expanded thank you messages (25 total)
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
    _initializeAnimations();
    _saveOrderToFirestore();
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

  // Save order to Firestore
  Future<void> _saveOrderToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update estimated delivery to add 9 days from order date
        final orderDate = widget.orderData['orderDate'] as DateTime;
        final updatedEstimatedDelivery = orderDate.add(Duration(days: 9));

        // Prepare order data for Firestore
        final orderToSave = {
          // Order Basic Information
          'orderNumber': widget.orderData['orderNumber'],
          'orderDate': widget.orderData['orderDate'],
          'estimatedDelivery': updatedEstimatedDelivery, // Updated delivery date (9 days)
          'status': 'order_placed', // Initial status

          // Customer Information
          'customerInfo': {
            'name': widget.orderData['customerInfo']['name'],
            'email': widget.orderData['customerInfo']['email'],
            'mobile': widget.orderData['customerInfo']['mobile'],
          },

          // Delivery Address
          'deliveryAddress': {
            'fullName': widget.orderData['deliveryAddress']['fullName'],
            'address': widget.orderData['deliveryAddress']['address'],
            'addressType': widget.orderData['deliveryAddress']['addressType'],
          },

          // Order Items
          'items': widget.orderData['items'].map((item) => {
            'id': item['id'],
            'name': item['name'],
            'image': item['image'],
            'price': item['price'],
            'quantity': item['quantity'] ?? 1,
            'selectedSize': item['selectedSize'],
            'selectedColor': item['selectedColor'],
          }).toList(),

          // Pricing Details
          'pricing': {
            'subtotal': widget.orderData['pricing']['subtotal'],
            'tax': widget.orderData['pricing']['tax'],
            'shipping': widget.orderData['pricing']['shipping'],
            'grandTotal': widget.orderData['pricing']['grandTotal'],
            'totalItems': widget.orderData['pricing']['totalItems'],
          },

          // Payment Information
          'payment': {
            'paymentId': widget.orderData['payment']['paymentId'],
            'razorpayOrderId': widget.orderData['payment']['razorpayOrderId'],
            'signature': widget.orderData['payment']['signature'],
            'method': widget.orderData['payment']['method'],
            'status': widget.orderData['payment']['status'],
            'amount': widget.orderData['payment']['amount'],
          },

          // Additional fields for order management
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isRated': false, // For rating functionality
          'rating': null,
          'review': null,
        };

        // Save to Firestore under users/{userId}/order_placed/{orderNumber}
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(widget.orderData['orderNumber'])
            .set(orderToSave);

        print('Order saved to Firestore successfully: ${widget.orderData['orderNumber']}');
      }
    } catch (e) {
      print('Error saving order to Firestore: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to save order. Please contact support if this persists.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _getUniqueThankYouMessage() {
    // Use order number to generate consistent but unique message for each order
    final orderNumber = widget.orderData['orderNumber'].toString();
    final seed = orderNumber.hashCode;
    final random = Random(seed);
    return _thankYouMessages[random.nextInt(_thankYouMessages.length)];
  }

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
      await invoiceService.generateInvoice(widget.orderData);

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
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(widget.orderData['orderNumber'])
            .update({
          'isRated': true,
          'rating': rating,
          'review': review.isNotEmpty ? review : null,
          'ratedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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
    } catch (e) {
      print('Error saving rating: $e');
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

  @override
  Widget build(BuildContext context) {
    final customerInfo = widget.orderData['customerInfo'] as Map<String, dynamic>;
    final deliveryAddress = widget.orderData['deliveryAddress'] as Map<String, dynamic>;
    final addressData = deliveryAddress['address'] as Map<String, dynamic>;
    final items = widget.orderData['items'] as List<Map<String, dynamic>>;
    final pricing = widget.orderData['pricing'] as Map<String, dynamic>;
    final payment = widget.orderData['payment'] as Map<String, dynamic>;
    final orderDate = widget.orderData['orderDate'] as DateTime;
    // Updated estimated delivery to 9 days from order date
    final estimatedDelivery = orderDate.add(Duration(days: 9));

    final fullAddress = '${addressData['building'] ?? ''}, ${addressData['area'] ?? ''}, ${addressData['landmark'] != null && addressData['landmark'].isNotEmpty ? '${addressData['landmark']}, ' : ''}${addressData['city'] ?? ''}, ${addressData['state'] ?? ''} - ${addressData['pincode'] ?? ''}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header with Invoice Button
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
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
                          'Order Placed',
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        // Invoice Button
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
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Message
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Order Placed Successfully!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Order #${widget.orderData['orderNumber']}',
                                  style: TextStyle(
                                    color: Color(0xFFD2691E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Thank you for your purchase! Your order has been confirmed and will be delivered soon.',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Unique Thank You Message
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
                          child: _buildOrderInformation(orderDate, estimatedDelivery),
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
                          child: _buildDeliveryAddress(customerInfo, deliveryAddress, fullAddress),
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
                        ...items.asMap().entries.map((entry) {
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
                        }).toList(),
                        SizedBox(height: 24),

                        // Price Breakdown
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(0.5, 0.9, curve: Curves.easeOutCubic),
                          )),
                          child: _buildPriceBreakdown(pricing),
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
                          child: _buildPaymentInfo(payment),
                        ),
                        SizedBox(height: 24),

                        // Need Help? Widget
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(0.7, 1.0, curve: Curves.easeOutCubic),
                          )),
                          child: _buildCustomerSupport(),
                        ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom Section with Two Buttons
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniqueThankYouMessage() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
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
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD2691E).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative elements
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

          // Main thank you message
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

          // Subtitle
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
          SizedBox(height: 16),

          // Bottom decorative line
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFD2691E),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformation(DateTime orderDate, DateTime estimatedDelivery) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
                        '#${widget.orderData['orderNumber']}',
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

          // Order Date
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

          // Estimated Delivery
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

  Widget _buildDeliveryAddress(Map<String, dynamic> customerInfo, Map<String, dynamic> deliveryAddress, String fullAddress) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
                deliveryAddress['fullName'],
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
            fullAddress,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          // Contact Information
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
                customerInfo['mobile'],
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
                  customerInfo['email'],
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

  Widget _buildOrderItem(Map<String, dynamic> item) {
    double itemPrice = double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
    int quantity = item['quantity'] ?? 1;
    double totalItemPrice = itemPrice * quantity;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'order_item_${item['id']}',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
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
                      '₹${totalItemPrice.toStringAsFixed(0)}',
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

  Widget _buildPriceBreakdown(Map<String, dynamic> pricing) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
          _buildPriceRow('Subtotal (${pricing['totalItems']} items)', '₹${pricing['subtotal'].toStringAsFixed(0)}'),
          _buildPriceRow('Tax (GST 18%)', '₹${pricing['tax'].toStringAsFixed(0)}'),
          _buildPriceRow(
            'Shipping',
            pricing['shipping'] == 0 ? 'FREE' : '₹${pricing['shipping'].toStringAsFixed(0)}',
            isShipping: true,
          ),
          Divider(color: Colors.grey[700], height: 24, thickness: 1),
          _buildPriceRow(
            'Total Amount',
            '₹${pricing['grandTotal'].toStringAsFixed(0)}',
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
          Row(
            children: [
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
                ),
              if (!(isShipping && value == 'FREE'))
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
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Map<String, dynamic> payment) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
                'Razorpay',
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
                  payment['paymentId'],
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
                  'Completed',
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

  Widget _buildCustomerSupport() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Continue Shopping Button (Outlined)
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD2691E),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Shop More',
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            // Rate Order Button (Filled)
            Expanded(
              child: ElevatedButton(
                onPressed: _rateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD2691E),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 4,
                  shadowColor: Color(0xFFD2691E).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rate,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Rate Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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

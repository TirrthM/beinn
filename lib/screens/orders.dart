import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_details.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _staggerAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('🚀 OrdersScreen initState called');
    _initializeAnimations();
    _loadOrdersFromFirestore();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _staggerController = AnimationController(
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
      begin: Offset(0, 0.5),
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

    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) _staggerController.forward();
    });
  }

  // ROBUST order loading with extensive debugging
  Future<void> _loadOrdersFromFirestore() async {
    try {
      print('🔍 === STARTING ORDER FETCH ===');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Please log in to view your orders';
        });
        return;
      }

      print('✅ User authenticated: ${user.uid}');
      print('📧 User email: ${user.email}');

      final orderPlacedRef =
      _firestore.collection('users').doc(user.uid).collection('order_placed');

      print('🔍 Querying collection: users/${user.uid}/order_placed');

      final snapshot = await orderPlacedRef.get();

      print('📊 Raw query result: ${snapshot.docs.length} documents found');
      print('📊 Snapshot metadata: ${snapshot.metadata}');
      print('📊 Is from cache: ${snapshot.metadata.isFromCache}');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No documents found in order_placed collection');

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        print('👤 User document exists: ${userDoc.exists}');

        if (userDoc.exists) {
          print('👤 User document data keys: ${userDoc.data()?.keys.toList()}');
        }

        setState(() {
          _orders = [];
          _isLoading = false;
          _hasError = false;
        });
        return;
      }

      List<Map<String, dynamic>> orders = [];

      for (var doc in snapshot.docs) {
        try {
          print('📄 Processing document: ${doc.id}');
          final data = doc.data();

          print('📄 Raw document data: $data');
          print('📄 Document keys: ${data.keys.toList()}');

          Map<String, dynamic> orderData = {
            'id': doc.id,
            'orderNumber': data['orderNumber'] ?? doc.id,
            'status': data['status'] ?? 'order_placed',
            'isRated': data['isRated'] ?? false,
            'rating': data['rating'],
            'review': data['review'],
            'ratedAt': data['ratedAt'],
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          };

          if (data['orderDate'] != null) {
            if (data['orderDate'] is Timestamp) {
              orderData['orderDate'] = (data['orderDate'] as Timestamp).toDate();
            } else if (data['orderDate'] is String) {
              orderData['orderDate'] =
                  DateTime.tryParse(data['orderDate']) ?? DateTime.now();
            }
          } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            orderData['orderDate'] = (data['createdAt'] as Timestamp).toDate();
          } else {
            orderData['orderDate'] = DateTime.now();
          }

          if (data['estimatedDelivery'] != null) {
            if (data['estimatedDelivery'] is Timestamp) {
              orderData['estimatedDelivery'] =
                  (data['estimatedDelivery'] as Timestamp).toDate();
            } else if (data['estimatedDelivery'] is String) {
              orderData['estimatedDelivery'] =
                  DateTime.tryParse(data['estimatedDelivery']) ??
                      DateTime.now().add(Duration(days: 7));
            }
          } else {
            orderData['estimatedDelivery'] =
                (orderData['orderDate'] as DateTime).add(Duration(days: 7));
          }

          orderData['customerInfo'] = data['customerInfo'] ?? {};
          print('👤 Customer info: ${orderData['customerInfo']}');

          orderData['deliveryAddress'] = data['deliveryAddress'] ?? {};
          print('📍 Delivery address: ${orderData['deliveryAddress']}');

          orderData['items'] = data['items'] ?? [];
          print('🛍️ Items count: ${(orderData['items'] as List).length}');
          if ((orderData['items'] as List).isNotEmpty) {
            print('🛍️ First item: ${(orderData['items'] as List)[0]}');
          }

          orderData['pricing'] = data['pricing'] ?? {};
          print('💰 Pricing: ${orderData['pricing']}');

          orderData['payment'] = data['payment'] ?? {};
          print('💳 Payment: ${orderData['payment']}');

          orders.add(orderData);
          print('✅ Successfully processed order: ${orderData['orderNumber']}');
        } catch (e) {
          print('❌ Error processing document ${doc.id}: $e');
          print('❌ Error stack trace: ${StackTrace.current}');
          continue;
        }
      }

      orders.sort((a, b) {
        DateTime dateA = a['orderDate'] ?? DateTime.now();
        DateTime dateB = b['orderDate'] ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      print('🎉 === ORDER FETCH COMPLETE ===');
      print('🎉 Total orders processed: ${orders.length}');

      setState(() {
        _orders = orders;
        _isLoading = false;
        _hasError = false;
      });

      for (int i = 0; i < _orders.length; i++) {
        final order = _orders[i];
        print(
            '📋 Order ${i + 1}: ${order['orderNumber']} - ${order['orderDate']} - Items: ${(order['items'] as List).length}');
      }
    } catch (e, stackTrace) {
      print('💥 CRITICAL ERROR in _loadOrdersFromFirestore: $e');
      print('💥 Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshOrders() async {
    print('🔄 Refreshing orders...');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    await _loadOrdersFromFirestore();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  void _rateOrder(Map<String, dynamic> order) async {
    int selectedRating = 0;
    TextEditingController reviewController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Rate Your Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'How was your shopping experience?',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
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
                        selectedRating > index ? Icons.star : Icons.star_border,
                        color: Color(0xFFD2691E),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: reviewController,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your review (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[600]!),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedRating > 0
                          ? () async {
                        await _saveRatingToFirestore(
                            order, selectedRating, reviewController.text.trim());
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD2691E),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Submit Rating',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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

  Future<void> _saveRatingToFirestore(
      Map<String, dynamic> order, int rating, String review) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('💾 Saving rating for order: ${order['orderNumber']}');

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('order_placed')
            .doc(order['orderNumber'])
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
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Thank you for rating us $rating stars!'),
                ],
              ),
              backgroundColor: Color(0xFFD2691E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }

        setState(() {
          final orderIndex =
          _orders.indexWhere((o) => o['orderNumber'] == order['orderNumber']);
          if (orderIndex != -1) {
            _orders[orderIndex]['isRated'] = true;
            _orders[orderIndex]['rating'] = rating;
            _orders[orderIndex]['review'] = review.isNotEmpty ? review : null;
          }
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

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    print('🔄 Navigating to order details: ${order['orderNumber']}');
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailsScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  // Helper functions for safe data conversion
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleanValue = value.replaceAll(RegExp(r'[₹,\s]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - compact
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'My Orders',
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Spacer(),
                        if (_orders.isNotEmpty)
                          ScaleTransition(
                            scale: _staggerAnimation,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFD2691E).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Color(0xFFD2691E).withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_orders.length} ${_orders.length == 1 ? 'order' : 'orders'}',
                                style: TextStyle(
                                  color: Color(0xFFD2691E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'Loading your orders...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Fetching from order_placed collection',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: _refreshOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD2691E),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: Color(0xFFD2691E),
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(
                index * 0.1,
                1.0,
                curve: Curves.easeOutCubic,
              ),
            )),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeInOut,
                ),
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _staggerController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutBack,
                  ),
                )),
                child: _buildOrderCard(_orders[index], index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _staggerAnimation,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'No orders found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 6),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'Your order history will appear here\nonce you place your first order',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              ScaleTransition(
                scale: _staggerAnimation,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD2691E),
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Start Shopping',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final orderDate = order['orderDate'] as DateTime;
    final pricing = order['pricing'] as Map<String, dynamic>? ?? {};
    final items = order['items'] as List<dynamic>? ?? [];
    final hasRating = order['isRated'] == true;

    int totalItems = _safeToInt(pricing['totalItems'] ?? items.length);
    double totalAmount = _safeToDouble(pricing['grandTotal'] ?? 0);

    return GestureDetector(
      onTap: () => _navigateToOrderDetails(order),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 80)),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main order info
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Placed at ${_formatDate(orderDate)}, ${_formatTime(orderDate)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        totalAmount > 0
                            ? '₹${totalAmount.toStringAsFixed(0)}'
                            : 'Amount not available',
                        style: TextStyle(
                          color: totalAmount > 0
                              ? Color(0xFFD2691E)
                              : Colors.grey[500],
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order['orderNumber']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[600],
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Items preview
                  if (items.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          // First item image
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: items[0]['image'] != null
                                  ? DecorationImage(
                                image: NetworkImage(items[0]['image']),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: items[0]['image'] == null
                                  ? Colors.grey[700]
                                  : null,
                            ),
                            child: items[0]['image'] == null
                                ? Icon(Icons.image,
                                color: Colors.grey[500], size: 18)
                                : null,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items.length == 1
                                      ? (items[0]['name'] ?? 'Product')
                                      : '${items[0]['name'] ?? 'Product'} and ${items.length - 1} more',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '$totalItems items',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasRating)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.green,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Rated',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              color: Colors.grey[500], size: 32),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Order items not available',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Rate Order Button (compact)
            if (!hasRating)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: ElevatedButton(
                  onPressed: () => _rateOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Color(0xFFD2691E),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rate,
                        color: Color(0xFFD2691E),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Rate Order',
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontSize: 14,
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
    _staggerController.dispose();
    super.dispose();
  }
}

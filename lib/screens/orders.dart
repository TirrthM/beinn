import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_details.dart';
import '../main.dart' as main_app;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
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

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('ðŸš€ OrdersScreen initState called');
    _initializeAnimations();
    _loadOrdersFromFirestore();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );

    // Start animations with staggered timing
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) _bounceController.forward();
    });
  }

  // ROBUST order loading with extensive debugging
  Future<void> _loadOrdersFromFirestore() async {
    try {
      print('ðŸ” === STARTING ORDER FETCH ===');

      final user = _auth.currentUser;
      if (user == null) {
        print('âŒ No authenticated user found');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Please log in to view your orders';
        });
        return;
      }

      print('âœ… User authenticated: ${user.uid}');
      print('ðŸ“§ User email: ${user.email}');

      final orderPlacedRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('order_placed');

      print('ðŸ” Querying collection: users/${user.uid}/order_placed');

      final snapshot = await orderPlacedRef.get();

      print('ðŸ“Š Raw query result: ${snapshot.docs.length} documents found');
      print('ðŸ“Š Snapshot metadata: ${snapshot.metadata}');
      print('ðŸ“Š Is from cache: ${snapshot.metadata.isFromCache}');

      if (snapshot.docs.isEmpty) {
        print('âš ï¸ No documents found in order_placed collection');

        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        print('ðŸ‘¤ User document exists: ${userDoc.exists}');

        if (userDoc.exists) {
          print(
              'ðŸ‘¤ User document data keys: ${userDoc.data()?.keys.toList()}');
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
          print('ðŸ“„ Processing document: ${doc.id}');
          final data = doc.data();

          print('ðŸ“„ Raw document data: $data');
          print('ðŸ“„ Document keys: ${data.keys.toList()}');

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
              orderData['orderDate'] =
                  (data['orderDate'] as Timestamp).toDate();
            } else if (data['orderDate'] is String) {
              orderData['orderDate'] =
                  DateTime.tryParse(data['orderDate']) ?? DateTime.now();
            }
          } else if (data['createdAt'] != null &&
              data['createdAt'] is Timestamp) {
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
                      DateTime.now().add(const Duration(days: 7));
            }
          } else {
            orderData['estimatedDelivery'] =
                (orderData['orderDate'] as DateTime)
                    .add(const Duration(days: 7));
          }

          orderData['customerInfo'] = data['customerInfo'] ?? {};
          print('ðŸ‘¤ Customer info: ${orderData['customerInfo']}');

          orderData['deliveryAddress'] = data['deliveryAddress'] ?? {};
          print('ðŸ“ Delivery address: ${orderData['deliveryAddress']}');

          orderData['items'] = data['items'] ?? [];
          print('ðŸ›ï¸ Items count: ${(orderData['items'] as List).length}');
          if ((orderData['items'] as List).isNotEmpty) {
            print('ðŸ›ï¸ First item: ${(orderData['items'] as List)[0]}');
          }

          orderData['pricing'] = data['pricing'] ?? {};
          print('ðŸ’° Pricing: ${orderData['pricing']}');

          orderData['payment'] = data['payment'] ?? {};
          print('ðŸ’³ Payment: ${orderData['payment']}');

          orders.add(orderData);
          print(
              'âœ… Successfully processed order: ${orderData['orderNumber']}');
        } catch (e) {
          print('âŒ Error processing document ${doc.id}: $e');
          print('âŒ Error stack trace: ${StackTrace.current}');
          continue;
        }
      }

      orders.sort((a, b) {
        DateTime dateA = a['orderDate'] ?? DateTime.now();
        DateTime dateB = b['orderDate'] ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      print('ðŸŽ‰ === ORDER FETCH COMPLETE ===');
      print('ðŸŽ‰ Total orders processed: ${orders.length}');

      setState(() {
        _orders = orders;
        _isLoading = false;
        _hasError = false;
      });

      for (int i = 0; i < _orders.length; i++) {
        final order = _orders[i];
        print(
            'ðŸ“‹ Order ${i + 1}: ${order['orderNumber']} - ${order['orderDate']} - Items: ${(order['items'] as List).length}');
      }
    } catch (e, stackTrace) {
      print('ðŸ’¥ CRITICAL ERROR in _loadOrdersFromFirestore: $e');
      print('ðŸ’¥ Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshOrders() async {
    print('ðŸ”„ Refreshing orders...');
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
        builder: (context, setModalState) => ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rate Your Order',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'How was your shopping experience?',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            selectedRating > index
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFBB694A),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write your review (optional)',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                                fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedRating > 0
                              ? () async {
                                  await _saveRatingToFirestore(
                                      order,
                                      selectedRating,
                                      reviewController.text.trim());
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBB694A),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveRatingToFirestore(
      Map<String, dynamic> order, int rating, String review) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('ðŸ’¾ Saving rating for order: ${order['orderNumber']}');

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

        print('âœ… Rating saved successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Thank you for rating us $rating stars!'),
                ],
              ),
              backgroundColor: const Color(0xFFBB694A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }

        setState(() {
          final orderIndex = _orders
              .indexWhere((o) => o['orderNumber'] == order['orderNumber']);
          if (orderIndex != -1) {
            _orders[orderIndex]['isRated'] = true;
            _orders[orderIndex]['rating'] = rating;
            _orders[orderIndex]['review'] = review.isNotEmpty ? review : null;
          }
        });
      }
    } catch (e) {
      print('âŒ Error saving rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save rating. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    print('ðŸ”„ Navigating to order details: ${order['orderNumber']}');
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailsScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const main_app.MainNavigationWrapper(initialIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeInOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
      (route) => false,
    );
  }

  // Helper functions for safe data conversion
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleanValue = value.replaceAll(RegExp(r'[\u20B9,\s]'), '');
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - compact
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Text(
                                'My Orders',
                                style: TextStyle(
                                  color: Color(0xFFBB694A),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (_orders.isNotEmpty)
                                ScaleTransition(
                                  scale: _bounceAnimation,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBB694A)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFBB694A)
                                            .withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${_orders.length} ${_orders.length == 1 ? 'order' : 'orders'}',
                                      style: const TextStyle(
                                        color: Color(0xFFBB694A),
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
                        child: _buildContent(isDark),
                      ),
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
            const CircularProgressIndicator(
              color: Color(0xFFBB694A),
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading your orders...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fetching from order_placed collection',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _refreshOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB694A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
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
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: const Color(0xFFBB694A),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .animate(
              CurvedAnimation(
                  parent: _slideController,
                  curve:
                      Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic)),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                    parent: _fadeController,
                    curve:
                        Interval(index * 0.08, 1.0, curve: Curves.easeInOut)),
              ),
              child: _buildOrderCard(_orders[index], index, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _bounceAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'No orders found',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'Your order history will appear here\nonce you place your first order',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _bounceAnimation,
                child: ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB694A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFBB694A).withValues(alpha: 0.2),
                  ),
                  child: const Row(
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

  Widget _buildOrderCard(Map<String, dynamic> order, int index, bool isDark) {
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main order info
            Padding(
              padding: const EdgeInsets.all(14),
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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalAmount > 0
                            ? '\u20B9${totalAmount.toStringAsFixed(0)}'
                            : 'Amount not available',
                        style: TextStyle(
                          color: totalAmount > 0
                              ? const Color(0xFFBB694A)
                              : Colors.grey[500],
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order['orderNumber']}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Items preview
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            width: 1),
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
                                      image: items[0]['image']
                                              .toString()
                                              .startsWith('assets/')
                                          ? AssetImage(items[0]['image'])
                                              as ImageProvider
                                          : NetworkImage(items[0]['image']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: items[0]['image'] == null
                                  ? (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300])
                                  : null,
                            ),
                            child: items[0]['image'] == null
                                ? Icon(Icons.image,
                                    color: Colors.grey[500], size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items.length == 1
                                      ? (items[0]['name'] ?? 'Product')
                                      : '${items[0]['name'] ?? 'Product'} and ${items.length - 1} more',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalItems items',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasRating)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[400],
                              size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Order items not available',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: ElevatedButton(
                  onPressed: () => _rateOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFFBB694A),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rate,
                        color: Color(0xFFBB694A),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Rate Order',
                        style: TextStyle(
                          color: Color(0xFFBB694A),
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
    _bounceController.dispose();
    super.dispose();
  }
}

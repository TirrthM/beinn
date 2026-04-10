import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' as main_app;
import '../theme_notifier.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
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
  bool _isLoading = true;

  // Track wishlist status for each item
  Set<String> _wishlistItemIds = Set<String>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCartFromFirestore();
    _loadWishlistStatus();
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

  // Load wishlist status for cart items
  Future<void> _loadWishlistStatus() async {
    try {
      await main_app.CartManager().loadWishlistFromFirestore();
      setState(() {
        _wishlistItemIds = main_app.CartManager()
            .wishlistItems
            .map((item) => item['id'].toString())
            .toSet();
      });
      // debug
      // print('Loaded wishlist status: $_wishlistItemIds');
    } catch (e) {
      // print('Error loading wishlist status: $e');
    }
  }

  // Check if item is in wishlist
  bool _isInWishlist(String productId) {
    return _wishlistItemIds.contains(productId);
  }

  // Load cart items from Firestore
  Future<void> _loadCartFromFirestore() async {
    try {
      final user = _auth.currentUser;
      // print('Loading cart for user: ${user?.uid}');

      if (user != null) {
        final cartSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .orderBy('addedAt', descending: false)
            .get();

        // Clear existing cart items
        main_app.CartManager().cartItems.clear();

        // Load items from Firestore
        for (var doc in cartSnapshot.docs) {
          final data = doc.data();

          final cartItem = {
            'id': data['productId'] ?? '',
            'name': data['productName'] ?? '',
            'price': '₹${data['discountedPrice']?.toInt() ?? 0}',
            'originalPrice': data['originalPrice'] != null
                ? '₹${data['originalPrice']?.toInt()}'
                : null,
            'image': data['productImage'] ?? '',
            'discount': data['discountPercentage'] ?? '',
            'selectedSize': data['selectedSize'] ?? '',
            'selectedColor': data['selectedColor'] ?? '',
            'quantity': data['quantity'] ?? 1,
            'images': List<String>.from(data['productImages'] ?? []),
            'sizes': List<String>.from(data['availableSizes'] ?? []),
            'colors': List<String>.from(data['availableColors'] ?? []),
            'description': data['productDescription'] ?? '',
            'details': data['productDetails'] ?? '',
            'category': data['productCategory'] ?? '',
          };
          main_app.CartManager().cartItems.add(cartItem);
        }
      }
    } catch (e) {
      // print('Error loading cart from Firestore: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeFromCart(String productId, String size, String color) async {
    setState(() {
      main_app.CartManager().removeFromCart(productId, size, color);
    });

    // Remove from Firestore
    await _removeCartItemFromFirestore(productId, size, color);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Item removed from cart',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.grey[850],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Remove cart item from Firestore
  Future<void> _removeCartItemFromFirestore(
      String productId, String size, String color) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docId = '${productId}_${size}_${color}';
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(docId)
            .delete();
      }
    } catch (e) {
      // print('Error removing cart item from Firestore: $e');
    }
  }

  // Toggle wishlist functionality
  void _toggleWishlist(Map<String, dynamic> product) async {
    final productId = product['id'].toString();
    final isCurrentlyInWishlist = _isInWishlist(productId);

    setState(() {
      if (isCurrentlyInWishlist) {
        _wishlistItemIds.remove(productId);
      } else {
        _wishlistItemIds.add(productId);
      }
    });

    if (isCurrentlyInWishlist) {
      // Remove from wishlist
      main_app.CartManager().removeFromWishlist(productId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.heart_broken, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product['name']} removed from wishlist',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Add to wishlist
      main_app.CartManager().addToWishlist(product);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product['name']} added to wishlist!',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFBB694A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _buyNow(Map<String, dynamic> product) {
    main_app.navigateToCheckout(context, [product]);
  }

  void _checkout() {
    if (main_app.CartManager().cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Your cart is empty', style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    main_app.navigateToCheckout(context, main_app.CartManager().cartItems);
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    main_app.navigateToProductDetail(context, product);
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            main_app.MainNavigationWrapper(initialIndex: 0),
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

  double _calculateItemTotal(Map<String, dynamic> item) {
    double price =
        double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
    int quantity = item['quantity'] ?? 1;
    return price * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFFAF9F5),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFFBB694A), strokeWidth: 2.5),
                  const SizedBox(height: 12),
                  Text('Loading your cart...',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15)),
                ],
              ),
            ),
          );
        }

        final cartItems = main_app.CartManager().cartItems;
        final totalAmount = main_app.CartManager().getTotalAmount();

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
                    // Header
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                color: Color(0xFFBB694A),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (cartItems.isNotEmpty)
                              ScaleTransition(
                                scale: _bounceAnimation,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBB694A)
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFBB694A)
                                          .withOpacity(0.28),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'}',
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
                    // Cart Content
                    Expanded(
                      child: cartItems.isEmpty
                          ? _buildEmptyCart(isDark)
                          : _buildCartList(cartItems, isDark),
                    ),
                    // Bottom Section with Total and Checkout
                    if (cartItems.isNotEmpty)
                      _buildBottomSection(totalAmount, isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(bool isDark) {
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1),
                  ),
                  child: Icon(Icons.shopping_cart_outlined,
                      size: 46,
                      color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                        .animate(
                  CurvedAnimation(
                      parent: _slideController,
                      curve:
                          const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
                ),
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.25), end: Offset.zero)
                    .animate(
                  CurvedAnimation(
                      parent: _slideController,
                      curve:
                          const Interval(0.5, 1.0, curve: Curves.easeOutCubic)),
                ),
                child: Text(
                  'Add items to your cart to see them here',
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 22),
              ScaleTransition(
                scale: _bounceAnimation,
                child: ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB694A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    shadowColor: const Color(0xFFBB694A).withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.home, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Continue Shopping',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildCartList(List<Map<String, dynamic>> cartItems, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(
            CurvedAnimation(
                parent: _slideController,
                curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                  parent: _fadeController,
                  curve: Interval(index * 0.08, 1.0, curve: Curves.easeInOut)),
            ),
            child: _buildCartItem(cartItems[index], index, isDark),
          ),
        );
      },
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, bool isDark) {
    final itemTotal = _calculateItemTotal(item);
    final isInWishlist = _isInWishlist(item['id'].toString());
    final String imageUrl = (item['image'] ?? '').toString();

    return GestureDetector(
      onTap: () => _navigateToProductDetail(item),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 320 + (index * 80)),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                Hero(
                  tag: 'cart_item_${item['id']}_$index',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: imageUrl.startsWith('assets/')
                                  ? AssetImage(imageUrl) as ImageProvider
                                  : NetworkImage(imageUrl),
                              fit: BoxFit.cover)
                          : null,
                      color: imageUrl.isEmpty
                          ? (isDark ? Colors.grey[800] : Colors.grey[200])
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? Icon(Icons.image_outlined,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 22)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Product',
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item['category'] != null &&
                          (item['category'] as String).isNotEmpty)
                        Text(
                          item['category'],
                          style: TextStyle(
                              color: const Color(0xFFBB694A).withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        item['category'] == 'Perfumes'
                            ? 'Type: ${item['selectedColor']}'
                            : 'Size: ${item['selectedSize']}  •  Color: ${item['selectedColor']}',
                        style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${itemTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Color(0xFFBB694A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (item['originalPrice'] != null)
                                Text(
                                  'Unit: ${item['price']}',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                      fontSize: 11),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB694A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      const Color(0xFFBB694A).withOpacity(0.28),
                                  width: 1),
                            ),
                            child: Text(
                              'Qty: ${item['quantity'] ?? 1}',
                              style: const TextStyle(
                                  color: Color(0xFFBB694A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    color: Colors.red[600]!,
                    onTap: () => _removeFromCart(item['id'],
                        item['selectedSize'], item['selectedColor']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildWishlistActionButton(
                      item: item, isInWishlist: isInWishlist, isDark: isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Buy Now',
                    color: const Color(0xFFBB694A),
                    onTap: () => _buyNow(item),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.28), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced wishlist button with toggle functionality
  Widget _buildWishlistActionButton({
    required Map<String, dynamic> item,
    required bool isInWishlist,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _toggleWishlist(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isInWishlist
              ? const Color(0xFFBB694A).withOpacity(0.12)
              : (isDark
                  ? Colors.grey[700]!.withOpacity(0.08)
                  : Colors.grey[700]!.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isInWishlist
                ? const Color(0xFFBB694A).withOpacity(0.5)
                : (isDark
                    ? Colors.grey[600]!.withOpacity(0.28)
                    : Colors.grey[400]!.withOpacity(0.5)),
            width: isInWishlist ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist
                    ? const Color(0xFFBB694A)
                    : (isDark ? Colors.grey[600]! : Colors.grey[500]!),
                size: 16,
                key: ValueKey<bool>(isInWishlist),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: isInWishlist
                    ? const Color(0xFFBB694A)
                    : (isDark ? Colors.grey[600]! : Colors.grey[600]!),
                fontSize: 12,
                fontWeight: isInWishlist ? FontWeight.w600 : FontWeight.w600,
              ),
              child: const Text('Wishlist'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(double totalAmount, bool isDark) {
    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _slideController,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          border: Border(
              top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1)),
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
                    Text('Total Amount',
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Color(0xFFBB694A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${main_app.CartManager().getCartItemCount()} items',
                      style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Checkout Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB694A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    elevation: 2,
                    shadowColor: const Color(0xFFBB694A).withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_cart_checkout,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Checkout',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}

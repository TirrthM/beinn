import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' as main_app;
import '../theme_notifier.dart';

class WishlistScreen extends StatefulWidget {
  final List<Map<String, dynamic>> wishlistItems;
  final Function(String) onRemoveFromWishlist;

  const WishlistScreen({
    super.key,
    required this.wishlistItems,
    required this.onRemoveFromWishlist,
  });

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWishlistFromFirestore();
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

  // Load wishlist items from Firestore
  Future<void> _loadWishlistFromFirestore() async {
    try {
      await main_app.CartManager().loadWishlistFromFirestore();
      print('Wishlist loaded in WishlistScreen');
    } catch (e) {
      print('Error loading wishlist in WishlistScreen: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFFAF9F5),
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBB694A),
              ),
            ),
          );
        }

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
                    // Header with box-style back button and title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            // Box-style Back Button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      isDark ? Colors.grey[800] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: isDark ? Colors.white : Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Title
                            const Expanded(
                              child: Text(
                                'My Wishlist',
                                style: TextStyle(
                                  color: Color(0xFFBB694A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Item count with animation
                            ScaleTransition(
                              scale: _bounceAnimation,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBB694A)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFBB694A)
                                        .withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${main_app.CartManager().wishlistItems.length} items',
                                  style: const TextStyle(
                                    color: Color(0xFFBB694A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Wishlist Content
                    Expanded(
                      child: main_app.CartManager().wishlistItems.isEmpty
                          ? _buildEmptyWishlist(isDark)
                          : _buildWishlistGrid(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWishlist(bool isDark) {
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
                  child: Icon(
                    Icons.favorite_outline,
                    size: 46,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
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
                  'Your wishlist is empty',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
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
                  'Save items you like to see them here',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFBB694A).withValues(alpha: 0.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Continue Shopping',
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

  Widget _buildWishlistGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: main_app.CartManager().wishlistItems.length,
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
              child: _buildWishlistItem(
                  main_app.CartManager().wishlistItems[index], index, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistItem(
      Map<String, dynamic> product, int index, bool isDark) {
    return GestureDetector(
      onTap: () => main_app.navigateToProductDetail(context, product),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'wishlist_item_${product['id']}_$index',
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          product['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(Icons.error,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (product['discount'] != null &&
                      product['discount'].isNotEmpty &&
                      product['discount'] != '0% OFF')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB694A),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFBB694A)
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            product['discount'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _removeFromWishlist(product);
                      },
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFF5F5F5)
                                      .withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: isDark
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFFBB694A),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product['price'],
                          style: const TextStyle(
                            color: Color(0xFFBB694A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (product['originalPrice'] != null)
                          Expanded(
                            child: Text(
                              product['originalPrice'],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
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

  void _removeFromWishlist(Map<String, dynamic> product) async {
    setState(() {
      main_app.CartManager().removeFromWishlist(product['id']);
    });
    widget.onRemoveFromWishlist(product['id']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.heart_broken, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${product['name']} removed from wishlist',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' as main_app;

class WishlistScreen extends StatefulWidget {
  final List<Map<String, dynamic>> wishlistItems;
  final Function(String) onRemoveFromWishlist;

  const WishlistScreen({
    Key? key,
    required this.wishlistItems,
    required this.onRemoveFromWishlist,
  }) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _staggerAnimation;

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

    _bounceController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: Duration(milliseconds: 1500),
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

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    ));

    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with staggered timing
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) _bounceController.forward();
    });
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) _staggerController.forward();
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFD2691E),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your wishlist...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                // Header with box-style back button and title
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Box-style Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
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
                        // Title
                        Expanded(
                          child: Text(
                            'My Wishlist',
                            style: TextStyle(
                              color: Color(0xFFD2691E),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Item count with animation
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFD2691E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFFD2691E).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFD2691E).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${main_app.CartManager().wishlistItems.length} items',
                              style: TextStyle(
                                color: Color(0xFFD2691E),
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
                      ? _buildEmptyWishlist()
                      : _buildWishlistGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWishlist() {
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
                  duration: Duration(milliseconds: 600),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'Your wishlist is empty',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                )),
                child: Text(
                  'Add items you love to your wishlist.\nReview them anytime and easily move them to bag.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              ScaleTransition(
                scale: _bounceAnimation,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD2691E),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                    shadowColor: Color(0xFFD2691E).withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Continue Shopping',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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

  Widget _buildWishlistGrid() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: GridView.builder(
        physics: BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: main_app.CartManager().wishlistItems.length,
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
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _staggerController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.elasticOut,
                  ),
                )),
                child: _buildWishlistItem(main_app.CartManager().wishlistItems[index], index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> product, int index) {
    return GestureDetector(
      onTap: () => main_app.navigateToProductDetail(context, product),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutCubic,
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'wishlist_item_${product['id']}_$index',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        image: DecorationImage(
                          image: NetworkImage(product['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (product['discount'] != null && product['discount'].isNotEmpty && product['discount'] != '0% OFF')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFD2691E),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFD2691E).withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            product['discount'],
                            style: TextStyle(
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
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFFD2691E).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Color(0xFFD2691E),
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
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product['price'],
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        if (product['originalPrice'] != null)
                          Expanded(
                            child: Text(
                              product['originalPrice'],
                              style: TextStyle(
                                color: Colors.grey[500],
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
            Icon(Icons.heart_broken, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${product['name']} removed from wishlist',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: Duration(seconds: 2),
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
    _staggerController.dispose();
    super.dispose();
  }
}
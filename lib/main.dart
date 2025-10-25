import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome.dart';
import 'screens/home.dart';
import 'screens/cart.dart';
import 'screens/orders.dart';
import 'screens/profile.dart';
import 'screens/wishlist.dart';
import 'screens/product_detail.dart';
import 'screens/checkout.dart';
import 'screens/category_products.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(BeinnApp());
}

class BeinnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beinn - Premium Clothing',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'SF Pro Display',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check Firebase Auth state
      final currentUser = FirebaseAuth.instance.currentUser;
      // Check SharedPreferences for login status
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final savedUserId = prefs.getString('userId');

      // User is considered logged in if:
      // 1. Firebase user exists AND
      // 2. SharedPreferences shows logged in AND
      // 3. User IDs match
      bool shouldShowHome = currentUser != null &&
          isLoggedIn &&
          savedUserId == currentUser.uid;

      setState(() {
        _isLoggedIn = shouldShowHome;
        _isLoading = false;
      });

      // If user exists in Firebase but not in SharedPreferences, update it
      if (currentUser != null && !isLoggedIn) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', currentUser.uid);
        setState(() {
          _isLoggedIn = true;
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFD2691E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFD2691E).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'BEINN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD2691E),
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Color(0xFFD2691E),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? MainNavigationWrapper() : WelcomeScreen();
  }
}

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
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
  }
}

// Global Cart Manager with Firebase Integration
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _wishlistItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;

  // Helper method to determine category from product name
  String _getCategoryFromProductName(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('t-shirt') || name.contains('tshirt')) return 'T-Shirts';
    if (name.contains('hoodie')) return 'Hoodies';
    if (name.contains('sweatshirt')) return 'Sweatshirts';
    if (name.contains('shirt')) return 'Shirts';
    if (name.contains('polo')) return 'Polo';
    if (name.contains('tank')) return 'Tank Tops';
    if (name.contains('sweatpants')) return 'Sweatpants';
    if (name.contains('shorts')) return 'Shorts';
    return 'Clothing';
  }

  // Save cart item to Firestore
  Future<void> _saveCartItemToFirestore(Map<String, dynamic> item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Saving cart item for user: ${user?.uid}');

      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        final docId = '${item['id']}_${item['selectedSize']}_${item['selectedColor']}';
        print('Document ID: $docId');

        // Extract numeric values from price strings
        final discountedPrice = double.parse(item['price'].toString().replaceAll('₹', '').replaceAll(',', ''));
        final originalPrice = item['originalPrice'] != null
            ? double.parse(item['originalPrice'].toString().replaceAll('₹', '').replaceAll(',', ''))
            : discountedPrice;

        // Calculate discount percentage
        final discountPercentage = item['originalPrice'] != null
            ? '${(((originalPrice - discountedPrice) / originalPrice) * 100).round()}% OFF'
            : '0% OFF';

        final cartItemData = {
          'productId': item['id'],
          'productName': item['name'],
          'productCategory': item['category'] ?? _getCategoryFromProductName(item['name']),
          'productImage': item['image'],
          'productImages': item['images'] ?? [],
          'productDescription': item['description'] ?? '',
          'productDetails': item['details'] ?? '',
          'selectedSize': item['selectedSize'],
          'selectedColor': item['selectedColor'],
          'availableSizes': item['sizes'] ?? [],
          'availableColors': item['colors'] ?? [],
          'quantity': item['quantity'] ?? 1,
          'originalPrice': originalPrice,
          'discountedPrice': discountedPrice,
          'discountPercentage': discountPercentage,
          'totalPrice': discountedPrice * (item['quantity'] ?? 1),
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('Saving cart item data: ${cartItemData['productName']}');
        await cartRef.doc(docId).set(cartItemData, SetOptions(merge: true));
        print('Cart item saved successfully to Firestore');
      } else {
        print('No authenticated user found');
      }
    } catch (e) {
      print('Error saving cart item to Firebase: $e');
    }
  }

  // Save wishlist item to Firestore
  Future<void> _saveWishlistItemToFirestore(Map<String, dynamic> item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Saving wishlist item for user: ${user?.uid}');

      if (user != null) {
        final wishlistRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist');

        final docId = item['id'];
        print('Wishlist Document ID: $docId');

        // Extract numeric values from price strings
        final discountedPrice = double.parse(item['price'].toString().replaceAll('₹', '').replaceAll(',', ''));
        final originalPrice = item['originalPrice'] != null
            ? double.parse(item['originalPrice'].toString().replaceAll('₹', '').replaceAll(',', ''))
            : discountedPrice;

        // Calculate discount percentage
        final discountPercentage = item['originalPrice'] != null
            ? '${(((originalPrice - discountedPrice) / originalPrice) * 100).round()}% OFF'
            : '0% OFF';

        final wishlistItemData = {
          'productId': item['id'],
          'productName': item['name'],
          'productCategory': item['category'] ?? _getCategoryFromProductName(item['name']),
          'productImage': item['image'],
          'productImages': item['images'] ?? [],
          'productDescription': item['description'] ?? '',
          'productDetails': item['details'] ?? '',
          'availableSizes': item['sizes'] ?? [],
          'availableColors': item['colors'] ?? [],
          'originalPrice': originalPrice,
          'discountedPrice': discountedPrice,
          'discountPercentage': discountPercentage,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('Saving wishlist item data: ${wishlistItemData['productName']}');
        await wishlistRef.doc(docId).set(wishlistItemData, SetOptions(merge: true));
        print('Wishlist item saved successfully to Firestore');
      } else {
        print('No authenticated user found');
      }
    } catch (e) {
      print('Error saving wishlist item to Firebase: $e');
    }
  }

  // Load wishlist items from Firestore
  Future<void> loadWishlistFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Loading wishlist for user: ${user?.uid}');

      if (user != null) {
        final wishlistSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .orderBy('addedAt', descending: false)
            .get();

        print('Found ${wishlistSnapshot.docs.length} wishlist items in Firestore');

        // Clear existing wishlist items
        _wishlistItems.clear();

        // Load items from Firestore
        for (var doc in wishlistSnapshot.docs) {
          final data = doc.data();
          print('Loading wishlist item: ${data['productName']}');

          final wishlistItem = {
            'id': data['productId'] ?? '',
            'name': data['productName'] ?? '',
            'price': '₹${data['discountedPrice']?.toInt() ?? 0}',
            'originalPrice': data['originalPrice'] != null ? '₹${data['originalPrice']?.toInt()}' : null,
            'image': data['productImage'] ?? '',
            'discount': data['discountPercentage'] ?? '',
            'images': List<String>.from(data['productImages'] ?? []),
            'sizes': List<String>.from(data['availableSizes'] ?? []),
            'colors': List<String>.from(data['availableColors'] ?? []),
            'description': data['productDescription'] ?? '',
            'details': data['productDetails'] ?? '',
            'category': data['productCategory'] ?? '',
          };
          _wishlistItems.add(wishlistItem);
        }

        print('Wishlist loaded successfully with ${_wishlistItems.length} items');
      }
    } catch (e) {
      print('Error loading wishlist from Firestore: $e');
    }
  }

  void addToCart(Map<String, dynamic> product) async {
    print('Adding to cart: ${product['name']}');

    // Check if product already exists in cart with same size and color
    int existingIndex = _cartItems.indexWhere((item) =>
    item['id'] == product['id'] &&
        item['selectedSize'] == product['selectedSize'] &&
        item['selectedColor'] == product['selectedColor']);

    if (existingIndex != -1) {
      // Increase quantity if product exists
      int currentQuantity = _cartItems[existingIndex]['quantity'] ?? 1;
      int addingQuantity = product['quantity'] ?? 1;
      _cartItems[existingIndex]['quantity'] = currentQuantity + addingQuantity;
      print('Updated quantity for existing item');
    } else {
      // Add new product to cart
      _cartItems.add(product);
      print('Added new item to cart');
    }

    // Save to Firebase
    await _saveCartItemToFirestore(product);
  }

  void removeFromCart(String productId, String size, String color) {
    _cartItems.removeWhere((item) =>
    item['id'] == productId &&
        item['selectedSize'] == size &&
        item['selectedColor'] == color);

    // Remove from Firebase
    _removeCartItemFromFirebase(productId, size, color);
  }

  Future<void> _removeCartItemFromFirebase(String productId, String size, String color) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docId = '${productId}_${size}_${color}';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(docId)
            .delete();
        print('Cart item removed from Firebase: $docId');
      }
    } catch (e) {
      print('Error removing cart item from Firebase: $e');
    }
  }

  void addToWishlist(Map<String, dynamic> product) async {
    print('Adding to wishlist: ${product['name']}');

    if (!_wishlistItems.any((item) => item['id'] == product['id'])) {
      _wishlistItems.add(product);
      print('Added new item to wishlist');

      // Save to Firebase
      await _saveWishlistItemToFirestore(product);
    } else {
      print('Item already exists in wishlist');
    }
  }

  void removeFromWishlist(String productId) async {
    print('Removing from wishlist: $productId');

    _wishlistItems.removeWhere((item) => item['id'] == productId);

    // Remove from Firebase
    await _removeWishlistItemFromFirebase(productId);
  }

  Future<void> _removeWishlistItemFromFirebase(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(productId)
            .delete();
        print('Wishlist item removed from Firebase: $productId');
      }
    } catch (e) {
      print('Error removing wishlist item from Firebase: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item['id'] == productId);
  }

  double getTotalAmount() {
    double total = 0;
    for (var item in _cartItems) {
      double price = double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  int getCartItemCount() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  int getWishlistItemCount() {
    return _wishlistItems.length;
  }
}

// Main Navigation Wrapper
class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const MainNavigationWrapper({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainNavigationWrapperState createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _selectedIndex;
  late PageController _pageController;

  // Updated screens list - removed CategoriesScreen
  final List<Widget> _screens = [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  // Updated navigation items - removed Categories
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Cart',
    ),
    NavigationItem(
      icon: Icons.receipt_outlined,
      activeIcon: Icons.receipt,
      label: 'Orders',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              return Expanded(
                child: _buildNavItem(index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        splashColor: Color(0xFFD2691E).withOpacity(0.2),
        highlightColor: Color(0xFFD2691E).withOpacity(0.1),
        child: Container(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFFD2691E).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? Color(0xFFD2691E) : Colors.grey[500],
                      size: 24,
                    ),
                  ),
                  // Cart badge - updated index from 2 to 1 since Categories was removed
                  if (index == 1 && CartManager().getCartItemCount() > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Color(0xFFD2691E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${CartManager().getCartItemCount()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Color(0xFFD2691E) : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Navigation Item Model
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Navigation Helper for Wishlist
void navigateToWishlist(BuildContext context, List<Map<String, dynamic>> wishlistItems, Function(String) onRemoveFromWishlist) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => WishlistScreen(
        wishlistItems: wishlistItems,
        onRemoveFromWishlist: onRemoveFromWishlist,
      ),
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
      transitionDuration: Duration(milliseconds: 400),
    ),
  );
}

// Navigation Helper for Product Detail
void navigateToProductDetail(BuildContext context, Map<String, dynamic> product) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ProductDetailScreen(product: product),
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
      transitionDuration: Duration(milliseconds: 400),
    ),
  );
}

// NEW: Navigation Helper for Category Products
void navigateToCategoryProducts(BuildContext context, String categoryName) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CategoryProductsScreen(categoryName: categoryName),
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
      transitionDuration: Duration(milliseconds: 400),
    ),
  );
}

// Navigation Helper for Checkout
void navigateToCheckout(BuildContext context, List<Map<String, dynamic>> items) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CheckoutScreen(items: items),
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
      transitionDuration: Duration(milliseconds: 400),
    ),
  );
}
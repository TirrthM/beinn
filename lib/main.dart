import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'screens/profile_completion.dart';
import 'theme_notifier.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel', // ID
  'High Importance Notifications', // Name
  description: 'Used for important notifications',
  importance: Importance.max,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    await initTheme(); // Initialize theme preference
  } catch (e) {
    print('Initialization error: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const BeinnApp());
}

class BeinnApp extends StatelessWidget {
  const BeinnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beinn - Premium Clothing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB694A),
          primary: const Color(0xFFBB694A),
          secondary: const Color(0xFFBB694A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'SF Pro Display',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isProfileComplete = false;
  String _displayedText1 = "";
  String _displayedText2 = "";

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN (CURRENT): $token");

      if (token != null) {
        _saveTokenToBackend(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print("FCM TOKEN REFRESHED: $newToken");
        _saveTokenToBackend(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                highImportanceChannel.id,
                highImportanceChannel.name,
                channelDescription: highImportanceChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        print("FCM Token saved to backend");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  Future<void> _startAnimation() async {
    const text1 = "BEINN";
    const text2 = "Be Real";

    // No initial pause - start immediately
    // await Future.delayed(Duration(milliseconds: 0));

    // Animate BEINN - faster (150ms per char)
    for (int i = 0; i < text1.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _displayedText1 = text1.substring(0, i + 1);
        });
      }
    }

    // Pause between lines - reduced (100ms)
    await Future.delayed(const Duration(milliseconds: 100));

    // Animate Be Real - faster (50ms per char)
    for (int i = 0; i < text2.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _displayedText2 = text2.substring(0, i + 1);
        });
      }
    }

    // Final pause - reduced (500ms)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Start animation
      final animationFuture = _startAnimation();

      // Check Firebase Auth state
      final currentUser = FirebaseAuth.instance.currentUser;

      bool isLoggedIn = false;
      bool isProfileComplete = false;

      if (currentUser != null) {
        isLoggedIn = true;

        // Check Firestore for profile completion status
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            isProfileComplete = userDoc.data()?['profileComplete'] ?? false;
          }
        } catch (e) {
          print('Error checking profile status: $e');
        }
      }

      // Sync SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (isLoggedIn) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', currentUser!.uid);
      } else {
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userId');
      }

      // Wait for animation to finish
      await animationFuture;

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isProfileComplete = isProfileComplete;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isProfileComplete = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _isLoading
          ? Scaffold(
              key: const ValueKey('loading'),
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayedText1,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayedText2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (_isLoggedIn
              ? (_isProfileComplete
                  ? const MainNavigationWrapper(key: ValueKey('home'))
                  : ProfileCompletionScreen(
                      user: FirebaseAuth.instance.currentUser!))
              : const WelcomeScreen(key: ValueKey('welcome'))),
    );
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

  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _wishlistItems = [];

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

        final docId =
            '${item['id']}_${item['selectedSize']}_${item['selectedColor']}';
        print('Document ID: $docId');

        // Extract numeric values from price strings
        final discountedPrice = double.parse(
            item['price'].toString().replaceAll('₹', '').replaceAll(',', ''));
        final originalPrice = item['originalPrice'] != null
            ? double.parse(item['originalPrice']
                .toString()
                .replaceAll('₹', '')
                .replaceAll(',', ''))
            : discountedPrice;

        // Calculate discount percentage
        final discountPercentage = item['originalPrice'] != null
            ? '${(((originalPrice - discountedPrice) / originalPrice) * 100).round()}% OFF'
            : '0% OFF';

        final cartItemData = {
          'productId': item['id'],
          'productName': item['name'],
          'productCategory':
              item['category'] ?? _getCategoryFromProductName(item['name']),
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
        final discountedPrice = double.parse(
            item['price'].toString().replaceAll('₹', '').replaceAll(',', ''));
        final originalPrice = item['originalPrice'] != null
            ? double.parse(item['originalPrice']
                .toString()
                .replaceAll('₹', '')
                .replaceAll(',', ''))
            : discountedPrice;

        // Calculate discount percentage
        final discountPercentage = item['originalPrice'] != null
            ? '${(((originalPrice - discountedPrice) / originalPrice) * 100).round()}% OFF'
            : '0% OFF';

        final wishlistItemData = {
          'productId': item['id'],
          'productName': item['name'],
          'productCategory':
              item['category'] ?? _getCategoryFromProductName(item['name']),
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
        await wishlistRef
            .doc(docId)
            .set(wishlistItemData, SetOptions(merge: true));
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

        print(
            'Found ${wishlistSnapshot.docs.length} wishlist items in Firestore');

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
            'originalPrice': data['originalPrice'] != null
                ? '₹${data['originalPrice']?.toInt()}'
                : null,
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

        print(
            'Wishlist loaded successfully with ${_wishlistItems.length} items');
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

  Future<void> _removeCartItemFromFirebase(
      String productId, String size, String color) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docId = '${productId}_${size}_$color';
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
      double price =
          double.parse(item['price'].replaceAll('₹', '').replaceAll(',', ''));
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  int getCartItemCount() {
    return _cartItems.fold(
        0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  int getWishlistItemCount() {
    return _wishlistItems.length;
  }
}

// Main Navigation Wrapper
class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  _MainNavigationWrapperState createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _selectedIndex;
  late PageController _pageController;

  // Updated screens list - removed CategoriesScreen
  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark
              ? Colors.black
              : const Color.fromARGB(255, 250, 249, 245), // #FAF9F5
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]
                  : const Color.fromARGB(255, 250, 249, 245), // #FAF9F5
              border: Border(
                top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 70,
                child: Row(
                  children: List.generate(_navItems.length, (index) {
                    return Expanded(
                      child: _buildNavItem(index, isDark),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        splashColor: const Color(0xFFBB694A).withValues(alpha: 0.2),
        highlightColor: const Color(0xFFBB694A).withValues(alpha: 0.1),
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFBB694A).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? const Color(0xFFBB694A)
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      size: 24,
                    ),
                  ),
                  // Cart badge - updated index from 2 to 1 since Categories was removed
                  if (index == 1 && CartManager().getCartItemCount() > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB694A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${CartManager().getCartItemCount()}',
                          style: const TextStyle(
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
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFBB694A)
                      : (isDark ? Colors.grey[500] : Colors.grey[600]),
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
void navigateToWishlist(
    BuildContext context,
    List<Map<String, dynamic>> wishlistItems,
    Function(String) onRemoveFromWishlist) {
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
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

// Navigation Helper for Product Detail
void navigateToProductDetail(
    BuildContext context, Map<String, dynamic> product) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ProductDetailScreen(product: product),
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

// NEW: Navigation Helper for Category Products
void navigateToCategoryProducts(BuildContext context, String categoryName) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CategoryProductsScreen(categoryName: categoryName),
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

// Navigation Helper for Checkout
void navigateToCheckout(
    BuildContext context, List<Map<String, dynamic>> items) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CheckoutScreen(items: items),
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' as main_app;
import 'welcome.dart';
import 'dart:async';

import '../theme_notifier.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'chatbot.dart';
import '../data/products_data.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bannerSlideController;
  late AnimationController _sectionSwitchController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _bannerSlideAnimation;
  late Animation<Offset> _sectionSlideAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _showWelcomeCard = true;
  int _currentBannerIndex = 0;
  String _selectedSection = 'Clothing';
  Timer? _bannerTimer;

  PageController _bannerController = PageController();
  VideoPlayerController? _videoController;
  ScrollController _categoriesScrollController = ScrollController();
  bool _showSeeAll = true; // true for "See All", false for "Back"

  final List<Map<String, dynamic>> _bannerData = [
    {
      'title': 'FASHION',
      'subtitle': 'Summer Collection 2025',
      'offer': 'Up to 40% off',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=200&fit=crop',
    },
    {
      'title': 'NEW ARRIVALS',
      'subtitle': 'Winter Collection 2025',
      'offer': 'Up to 50% off',
      'image':
          'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=200&fit=crop',
    },
    {
      'title': 'TRENDING',
      'subtitle': 'Street Style Collection',
      'offer': 'Up to 30% off',
      'image':
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&h=200&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'T-Shirts',
      'type': 'image',
      'image':
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-7Zih6I1qFheS9XELo0orL76keeJi7H.png'
    },
    {
      'name': 'Shirts',
      'type': 'image',
      'image':'assets/images/shirtwithoutbg.png',
    },
    {
      'name': 'Hoodies',
      'type': 'image',
      'image':
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Hoodie_appimg.PNG-UkgfqGGPgl1p624MNH8gbsGFus8COx.png'
    },
    {
      'name': 'Sweatshirts',
      'type': 'image',
      'image':
          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Sweatshirt_appimg.PNG-stbgbQ97A0VBOYJiwv3GAzpP8JvyrA.png', 
    },
    {
      'name': 'Tank Tops',
      'type': 'image',
      'image':'assets/images/tanktopfinal.png',
    },
    {
      'name': 'Zipper Hoodies',
      'type': 'image',
      'image': 'assets/images/zipperhoodie.png',
    },
  ];

  final List<Map<String, dynamic>> _featuredProducts = [
    {
      'id': 'tshirt_acid_wash',
      'name': 'Acid Wash Oversized Tee',
      'price': '₹999',
      'originalPrice': '₹1499',
      'image': 'assets/images/oversized_tshirts/acid_wash/25.webp',
      'discount': '33% OFF',
      'images': [
        'assets/images/oversized_tshirts/acid_wash/25.webp',
        'assets/images/oversized_tshirts/acid_wash/29.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
      'variantLabel': 'Design',
      'colors': [
        'Beinn Left',
        'Unorthodox',
        'Nevermind',
        'Go To God First',
        'Beinn Middle'
      ],
      'colorImages': {
        'Beinn Left': [
          'assets/images/oversized_tshirts/acid_wash/25.webp',
          'assets/images/oversized_tshirts/acid_wash/29.webp'
        ],
        'Unorthodox': [
          'assets/images/oversized_tshirts/acid_wash/24.webp',
          'assets/images/oversized_tshirts/acid_wash/29.webp'
        ],
        'Nevermind': [
          'assets/images/oversized_tshirts/acid_wash/26.webp',
          'assets/images/oversized_tshirts/acid_wash/29.webp'
        ],
        'Go To God First': [
          'assets/images/oversized_tshirts/acid_wash/27.webp',
          'assets/images/oversized_tshirts/acid_wash/30.webp'
        ],
        'Beinn Middle': [
          'assets/images/oversized_tshirts/acid_wash/28.webp',
          'assets/images/oversized_tshirts/acid_wash/29.webp'
        ],
      },
      'description':
          'Premium acid wash oversized t-shirt with distinctive texture.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
      'details': '100% Cotton. Oversized fit. Machine wash cold.',
      'category': 'T-Shirts',
    },
    {
      'id': 'tshirt_beinn_flower',
      'name': 'Beinn Flower Edition',
      'price': '₹949',
      'originalPrice': '₹1399',
      'image': 'assets/images/oversized_tshirts/beinn_flower/35.webp',
      'discount': '32% OFF',
      'images': [
        'assets/images/oversized_tshirts/beinn_flower/35.webp',
        'assets/images/oversized_tshirts/back/40.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['White', 'Beige'],
      'colorImages': {
        'White': [
          'assets/images/oversized_tshirts/beinn_flower/35.webp',
          'assets/images/oversized_tshirts/back/40.webp'
        ],
        'Beige': [
          'assets/images/oversized_tshirts/beinn_flower/48.webp',
          'assets/images/oversized_tshirts/back/50.webp'
        ],
      },
      'description': 'Floral inspired design from the Beinn collection.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
      'details': 'Premium cotton blend. Modern fit.',
      'category': 'T-Shirts',
    },
    {
      'id': 'tank_4',
      'name': "Men's Plain Oversized Tank Top",
      'price': '₹599',
      'originalPrice': '₹899',
      'image': 'assets/images/tank_tops/plain/13.webp',
      'discount': '33% OFF',
      'images': [
        'assets/images/tank_tops/plain/13.webp',
        'assets/images/tank_tops/back/17.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['White', 'Maroon', 'Beige', 'Pearl Blue', 'Black', 'Grey'],
      'colorImages': {
        'White': [
          'assets/images/tank_tops/plain/13.webp',
          'assets/images/tank_tops/back/17.webp',
        ],
        'Maroon': [
          'assets/images/tank_tops/plain/25.webp',
          'assets/images/tank_tops/back/26.webp',
        ],
        // 'Beige': [
        // 'assets/images/tank_tops/plain/1.webp',
        // 'assets/images/tank_tops/back/6.webp',
        // ],
        'Pearl Blue': [
          'assets/images/tank_tops/plain/8.webp',
          'assets/images/tank_tops/back/11.webp',
        ],
        'Black': [
          'assets/images/tank_tops/plain/20.webp',
          'assets/images/tank_tops/back/21.webp',
        ],
        'Grey': [
          'assets/images/tank_tops/plain/29.webp',
          'assets/images/tank_tops/back/30.webp',
        ],
      },
      'description': 'Comfortable tank top perfect for gym and casual wear.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
      'details': 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
      'category': 'Tank Tops',
    },
    {
      'id': 'tank_3',
      'name': "Men's Real is Rare Oversized Tank Top",
      'price': '₹599',
      'originalPrice': '₹899',
      'image': 'assets/images/tank_tops/designs/42.webp',
      'discount': '33% OFF',
      'images': [
        'assets/images/tank_tops/designs/42.webp',
        'assets/images/tank_tops/back/30.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['Grey', 'Maroon', 'Beige', 'Pearl Blue', 'White', 'Black'],
      'colorImages': {
        'Grey': [
          'assets/images/tank_tops/designs/42.webp',
          'assets/images/tank_tops/back/30.webp',
        ],
        'Maroon': [
          'assets/images/tank_tops/designs/43.webp',
          'assets/images/tank_tops/back/26.webp',
        ],
        'Beige': [
          'assets/images/tank_tops/designs/4.webp',
          'assets/images/tank_tops/back/6.webp',
        ],
        'Pearl Blue': [
          'assets/images/tank_tops/designs/45.webp',
          'assets/images/tank_tops/back/11.webp',
        ],
        'White': [
          'assets/images/tank_tops/designs/46.webp',
          'assets/images/tank_tops/back/17.webp',
        ],
        'Black': [
          'assets/images/tank_tops/designs/44.webp',
          'assets/images/tank_tops/back/21.webp',
        ],
      },
      'description': 'Comfortable tank top perfect for gym and casual wear.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent. No bleach.\n• Gentle machine or hand wash.\n• Do not tumble dry. Dry in shade.\n• Iron inside out. No iron on print.',
      'details': 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
      'category': 'Tank Tops',
    },
    {
      'id': 'shirt_1',
      'name': 'Formal White Shirt',
      'price': '₹1599',
      'originalPrice': '₹2299',
      'image': 'assets/images/shirts/b_shirt/1.webp',
      'discount': '30% OFF',
      'images': [
        'assets/images/shirts/b_shirt/1.webp',
        'assets/images/shirts/back/3.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
      'colors': ['Beige', 'Blue', 'Charcoal Grey', 'White', 'Black'],
      'colorImages': {
        'Beige': [
          'assets/images/shirts/b_shirt/1.webp',
          'assets/images/shirts/back/3.webp'
        ],
        'Blue': [
          'assets/images/shirts/b_shirt/4.webp',
          'assets/images/shirts/back/6.webp'
        ],
        'Charcoal Grey': [
          'assets/images/shirts/b_shirt/7.webp',
          'assets/images/shirts/back/9.webp'
        ],
        'White': [
          'assets/images/shirts/b_shirt/10.webp',
          'assets/images/shirts/back/12.webp'
        ],
        'Black': [
          'assets/images/shirts/b_shirt/13.webp',
          'assets/images/shirts/back/15.webp'
        ],
      },
      'description':
          'Classic formal shirt perfect for office wear and business meetings.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
      'details': 'Premium cotton blend. Wrinkle-resistant. Professional fit.',
      'category': 'Shirts',
    },
    {
      'id': 'shirt_2',
      'name': 'Casual Denim Shirt',
      'price': '₹1299',
      'originalPrice': '₹1899',
      'image': 'assets/images/shirts/plain_t_shirt/5.webp',
      'discount': '32% OFF',
      'images': [
        'assets/images/shirts/plain_t_shirt/5.webp',
        'assets/images/shirts/back/6.webp',
      ],
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['Blue', 'Beige', 'Charcoal Grey', 'White', 'Black'],
      'colorImages': {
        'Blue': [
          'assets/images/shirts/plain_t_shirt/5.webp',
          'assets/images/shirts/back/6.webp'
        ],
        'Beige': [
          'assets/images/shirts/plain_t_shirt/2.webp',
          'assets/images/shirts/back/3.webp'
        ],
        'Charcoal Grey': [
          'assets/images/shirts/plain_t_shirt/8.webp',
          'assets/images/shirts/back/9.webp'
        ],
        'White': [
          'assets/images/shirts/plain_t_shirt/11.webp',
          'assets/images/shirts/back/12.webp'
        ],
        'Black': [
          'assets/images/shirts/plain_t_shirt/14.webp',
          'assets/images/shirts/back/15.webp'
        ],
      },
      'description': 'Casual denim shirt perfect for weekend outings.',
      'washCare':
          '• Wash inside out in cold water.\n• Use mild detergent only.\n• Do not bleach or tumble dry.\n• Gentle machine or hand wash.\n• Iron inside out. No iron on print.',
      'details': 'High-quality denim fabric. Classic fit.',
      'category': 'Shirts',
    },

  ];

  List<Map<String, dynamic>> get _featuredPerfumes {
    return ProductsData.getProductsByCategory('Perfumes')
        .map((p) => p.toMap())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    // _startBannerTimer();
    _initializeVideo();
    _checkWelcomeCardStatus();

    _setupScrollListener();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      print(message.notification?.title);
      print(message.notification?.body);
    });
  }

  void _setupScrollListener() {
    _categoriesScrollController.addListener(() {
      if (_categoriesScrollController.hasClients) {
        final maxScrollExtent =
            _categoriesScrollController.position.maxScrollExtent;
        final currentScrollPosition = _categoriesScrollController.offset;
        final threshold = maxScrollExtent * 0.5; // 50% threshold

        setState(() {
          _showSeeAll = currentScrollPosition < threshold;
        });
      }
    });
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

    _bannerSlideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _sectionSwitchController = AnimationController(
      duration: Duration(milliseconds: 400),
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

    _bannerSlideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerSlideController,
      curve: Curves.easeOutCubic,
    ));

    _sectionSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sectionSwitchController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _sectionSwitchController.forward();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(Duration(seconds: 7), (timer) {
      if (_currentBannerIndex < _bannerData.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/images/beinnvideo.mp4')
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown after the video is initialized
        _videoController!.setLooping(true);
        _videoController!.play();
      });
  }

  Future<void> _checkWelcomeCardStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final welcomeCardKey = 'welcome_card_dismissed_${currentUser.uid}';
        final isDismissed = prefs.getBool(welcomeCardKey) ?? false;
        setState(() {
          _showWelcomeCard = !isDismissed;
        });
      }
    } catch (e) {
      print('Error checking welcome card status: $e');
    }
  }

  Future<void> _dismissWelcomeCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final welcomeCardKey = 'welcome_card_dismissed_${currentUser.uid}';
        await prefs.setBool(welcomeCardKey, true);
        setState(() {
          _showWelcomeCard = false;
        });
        _bannerSlideController.forward();
      }
    } catch (e) {
      print('Error dismissing welcome card: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      // Clear welcome card status for this user
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final welcomeCardKey = 'welcome_card_dismissed_${currentUser.uid}';
        await prefs.remove(welcomeCardKey);
      }

      // Clear login status
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');

      // Sign out from Firebase
      await _auth.signOut();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(-1.0, 0.0),
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
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _toggleWishlist(Map<String, dynamic> product) {
    setState(() {
      if (main_app.CartManager().isInWishlist(product['id'])) {
        main_app.CartManager().removeFromWishlist(product['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product['name']} removed from wishlist',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        main_app.CartManager().addToWishlist(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product['name']} is added to your wishlist!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFFBB694A),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _removeFromWishlist(String productId) {
    setState(() {
      main_app.CartManager().removeFromWishlist(productId);
    });
  }

  void _navigateToWishlist() {
    main_app.navigateToWishlist(
        context, main_app.CartManager().wishlistItems, _removeFromWishlist);
  }

  void _scrollToEnd() {
    if (_categoriesScrollController.hasClients) {
      final maxScrollExtent =
          _categoriesScrollController.position.maxScrollExtent;
      _categoriesScrollController.animateTo(
        maxScrollExtent,
        duration: Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToStart() {
    if (_categoriesScrollController.hasClients) {
      _categoriesScrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleCategoryScroll() {
    if (_showSeeAll) {
      _scrollToEnd();
    } else {
      _scrollToStart();
    }
  }

  Widget _buildFixedHeader(bool isDark) {
    return Container(
      color: isDark ? Colors.black : const Color(0xFFFAF9F5),
      child: SafeArea(
        bottom: false,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBB694A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBB694A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'BEINN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB694A),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // Icons
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            main_app.CartManager().wishlistItems.isNotEmpty
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color:
                                main_app.CartManager().wishlistItems.isNotEmpty
                                    ? const Color(0xFFBB694A)
                                    : (isDark ? Colors.white : Colors.black),
                            size: 24,
                          ),
                          onPressed: _navigateToWishlist,
                        ),
                        if (main_app.CartManager().wishlistItems.isNotEmpty)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBB694A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.black
                                        : const Color(0xFFFAF9F5),
                                    width: 1),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${main_app.CartManager().wishlistItems.length}',
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    if (!_showWelcomeCard || _userData == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
      )),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFBB694A).withOpacity(0.1),
              const Color(0xFFBB694A).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBB694A).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFBB694A).withOpacity(0.2),
              backgroundImage: _currentUser?.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              child: _currentUser?.photoURL == null
                  ? const Icon(Icons.person, color: Color(0xFFBB694A), size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData != null
                        ? '${_userData!['firstName'] ?? ''} ${_userData!['lastName'] ?? ''}'
                            .trim()
                        : _currentUser?.displayName ?? 'User',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to explore premium clothing?',
                    style: TextStyle(
                      color: Color(0xFFBB694A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20),
              onPressed: _dismissWelcomeCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFBB694A))),
      );
    }
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      )),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: _showWelcomeCard ? 4 : 12,
        ),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerIndicators() {
    return const SizedBox.shrink();
  }

  void _switchSection(String section) {
    if (_selectedSection != section) {
      _sectionSwitchController.reset();
      setState(() {
        _selectedSection = section;
      });
      _sectionSwitchController.forward();
    }
  }

  Widget _buildSectionToggle(bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _switchSection('Clothing'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSection == 'Clothing'
                        ? const Color(0xFFBB694A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _selectedSection == 'Clothing'
                        ? [
                      BoxShadow(
                        color: const Color(0xFFBB694A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    'Clothing',
                    style: TextStyle(
                      color: _selectedSection == 'Clothing'
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _switchSection('Perfumes'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSection == 'Perfumes'
                        ? const Color(0xFFBB694A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _selectedSection == 'Perfumes'
                        ? [
                      BoxShadow(
                        color: const Color(0xFFBB694A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    'Perfumes',
                    style: TextStyle(
                      color: _selectedSection == 'Perfumes'
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(bool isDark) {
    if (_selectedSection != 'Clothing') return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleCategoryScroll,
                    child: Text(
                      _showSeeAll ? 'See All' : 'Back',
                      style: const TextStyle(
                        color: Color(0xFFBB694A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                controller: _categoriesScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () => main_app.navigateToCategoryProducts(
                        context, category['name']),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB694A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFBB694A).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: category['image'].startsWith('assets/')
                                    ? Image.asset(
                                        category['image'],
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.checkroom,
                                            color: Color(0xFFBB694A),
                                            size: 28,
                                          );
                                        },
                                      )
                                    : Image.network(
                                        category['image'],
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.checkroom,
                                            color: Color(0xFFBB694A),
                                            size: 28,
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFFBB694A),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(bool isDark) {
    return SlideTransition(
      position: _sectionSlideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _selectedSection == 'Clothing'
                    ? 'Featured Products'
                    : 'Premium Perfumes',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _selectedSection == 'Clothing'
                ? _buildClothingGrid(isDark)
                : _buildPerfumesGrid(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfumesGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _featuredPerfumes.length,
        itemBuilder: (context, index) {
          final product = _featuredPerfumes[index];
          return _buildProductCard(product, isDark);
        },
      ),
    );
  }

  Widget _buildClothingGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return _buildProductCard(product, isDark);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    final isWishlisted = main_app.CartManager().isInWishlist(product['id']);

    return GestureDetector(
      onTap: () => main_app.navigateToProductDetail(context, product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: product['image'].startsWith('assets/')
                            ? AssetImage(product['image']) as ImageProvider
                            : NetworkImage(product['image']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBB694A),
                        borderRadius: BorderRadius.circular(8),
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
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          color: isWishlisted
                              ? const Color(0xFFBB694A)
                              : Colors.white,
                          size: 16,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product['price'],
                          style: const TextStyle(
                            color: Color(0xFFBB694A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product['originalPrice'],
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500],
                              fontSize: 12,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            backgroundColor: const Color(0xFFBB694A),
            child: const Icon(Icons.mark_chat_unread_rounded,
                color: Colors.white), // Use a chat icon
            tooltip: 'Chat with Assistant',
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Fixed Header (without search bar)
                  _buildFixedHeader(isDark),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(isDark),
                          _buildBannerSection(),
                          _buildBannerIndicators(),
                          _buildSectionToggle(isDark),
                          _buildCategoriesSection(isDark),
                          _buildFeaturedProducts(isDark),
                          const SizedBox(
                              height: 100), // Bottom padding for navigation bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _bannerSlideController.dispose();
    _sectionSwitchController.dispose();

    _bannerTimer?.cancel();
    _bannerController.dispose();
    _videoController?.dispose();
    _categoriesScrollController.dispose();
    super.dispose();
  }
}

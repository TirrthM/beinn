import 'package:flutter/material.dart';
import '../main.dart' as main_app;
import '../theme_notifier.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  String _selectedSize = 'M';
  bool _isSizeChartExpanded = false;
  String _selectedColor = 'Black';
  int _selectedQuantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<int> _quantities = List.generate(10, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    if (widget.product['colors'] != null &&
        (widget.product['colors'] as List).isNotEmpty) {
      _selectedColor = widget.product['colors'][0];
    }
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
      begin: const Offset(0, 0.5),
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

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Start animations with staggered timing
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bounceController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _rotationController.forward();
    });
  }

  void _addToCart() {
    final cartItem = {
      ...widget.product,
      'selectedSize': _selectedSize,
      'selectedColor': _selectedColor,
      'quantity': _selectedQuantity,
    };

    main_app.CartManager().addToCart(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.product['name']} added to cart!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFBB694A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _buyNow() {
    final cartItem = {
      ...widget.product,
      'selectedSize': _selectedSize,
      'selectedColor': _selectedColor,
      'quantity': _selectedQuantity,
    };

    main_app.navigateToCheckout(context, [cartItem]);
  }

  void _toggleWishlist() {
    if (main_app.CartManager().isInWishlist(widget.product['id'])) {
      main_app.CartManager().removeFromWishlist(widget.product['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.heart_broken, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Removed from wishlist',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      main_app.CartManager().addToWishlist(widget.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Added to wishlist!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFBB694A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    setState(() {});
  }

  List<String> _getProductImages() {
    // 1. Check if colorImages exists and has the selected color
    if (widget.product['colorImages'] != null) {
      final colorImages = widget.product['colorImages'] as Map;
      // We need to handle potential key types or just checking string matching
      if (colorImages.containsKey(_selectedColor)) {
        final images = colorImages[_selectedColor] as List;
        if (images.isNotEmpty) {
          return images.map((e) => e.toString()).toList();
        }
      }
    }

    // 2. Check if the product has a generic list of images
    if (widget.product['images'] != null &&
        (widget.product['images'] as List).isNotEmpty) {
      return (widget.product['images'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // 3. Fallback if no images list but main image exists
    List<String> images = [];
    if (widget.product['image'] != null) {
      images.add(widget.product['image'].toString());
    } else {
      // Fallback placeholder images
      images.add(
          'https://via.placeholder.com/400x400/333333/FFFFFF?text=Product+Image+1');
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final isInWishlist =
        main_app.CartManager().isInWishlist(widget.product['id']);
    final images = _getProductImages();

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
                    // Header
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
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
                                          alpha: isDark ? 0.0 : 0.05),
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
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleWishlist,
                              child: RotationTransition(
                                turns: _rotationAnimation,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isInWishlist
                                        ? const Color(0xFFBB694A)
                                        : (isDark
                                            ? Colors.grey[800]
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.0 : 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isInWishlist
                                          ? Icons.favorite
                                          : Icons.favorite_outline,
                                      color: isInWishlist
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                      size: 20,
                                    ),
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
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Images
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: const Interval(0.0, 0.5,
                                    curve: Curves.easeOutCubic),
                              )),
                              child: _buildImageCarousel(images, isDark),
                            ),
                            const SizedBox(height: 24),
                            // Product Info
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(0.2, 0.7,
                                          curve: Curves.easeOutCubic),
                                    )),
                                    child: Text(
                                      widget.product['name'] ?? 'Product Name',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(0.3, 0.8,
                                          curve: Curves.easeOutCubic),
                                    )),
                                    child: Text(
                                      widget.product['price'] ?? '\u20B90',
                                      style: const TextStyle(
                                        color: Color(0xFFBB694A),
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (widget.product['category'] !=
                                      'Perfumes') ...[
                                    // Size Selection
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: _slideController,
                                        curve: const Interval(0.4, 0.9,
                                            curve: Curves.easeOutCubic),
                                      )),
                                      child: _buildSizeSelection(isDark),
                                    ),
                                    const SizedBox(height: 24),
                                    // Size Chart
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: _slideController,
                                        curve: const Interval(0.45, 0.95,
                                            curve: Curves.easeOutCubic),
                                      )),
                                      child: _buildSizeChart(isDark),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  // Color Selection
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 1.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(0.5, 1.0,
                                          curve: Curves.easeOutCubic),
                                    )),
                                    child: _buildColorSelection(isDark),
                                  ),
                                  const SizedBox(height: 24),
                                  // Quantity Selection
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 1.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(0.6, 1.0,
                                          curve: Curves.easeOutCubic),
                                    )),
                                    child: _buildQuantitySelection(isDark),
                                  ),
                                  const SizedBox(height: 24),
                                  // Product Description
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(0.65, 0.95,
                                          curve: Curves.easeOutCubic),
                                    )),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.grey[800]!
                                                : Colors.grey[300]!,
                                            width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                                alpha: isDark ? 0.0 : 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.description,
                                                color: Color(0xFFBB694A),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Description',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            widget.product['description'] ??
                                                'Premium quality clothing with excellent craftsmanship and attention to detail. Made from high-quality materials for comfort and durability.',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.product['washCare'] != null &&
                                      (widget.product['washCare'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(-1.0, 0.0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: _slideController,
                                        curve: const Interval(0.7, 1.0,
                                            curve: Curves.easeOutCubic),
                                      )),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: isDark
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!,
                                              width: 1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                  alpha: isDark ? 0.0 : 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.local_laundry_service,
                                                  color: Color(0xFFBB694A),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Wash Care',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              widget.product['washCare'],
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom Buttons
                    _buildBottomButtons(isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel(List<String> images, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: 'product_image_${widget.product['id']}_$index',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: images[index].startsWith('assets/')
                          ? AssetImage(images[index]) as ImageProvider
                          : NetworkImage(images[index]),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print(
                            'Error loading detail image ${images[index]} for product ${widget.product['name']}');
                        print('Exception: $exception');
                      },
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ScaleTransition(
          scale: _bounceAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentImageIndex == entry.key ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentImageIndex == entry.key
                      ? const Color(0xFFBB694A)
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeChart(bool isDark) {
    final isHoodie =
        widget.product['name'].toString().toLowerCase().contains('hoodie');

    // Headers
    final sizeLabels = ['Size', 'S', 'M', 'L', 'XL', 'XXL'];

    // Data Rows
    final chestData = isHoodie
        ? ['Chest', '38', '40', '42', '44', '46']
        : ['Chest', '36', '38', '40', '42', '44'];

    final lengthData = isHoodie
        ? ['Length', '26', '27', '28', '29', '30']
        : ['Length', '25', '26', '27', '28', '29'];

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isSizeChartExpanded = !_isSizeChartExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_chart,
                    color: Color(0xFFBB694A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Size Chart',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(
                _isSizeChartExpanded ? Icons.remove : Icons.add,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
            ],
          ),
        ),
        if (_isSizeChartExpanded) ...[
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                children: sizeLabels
                    .map((text) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // Chest Row
              TableRow(
                children: chestData
                    .map((text) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[800],
                              fontWeight: text == 'Chest'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // Length Row
              TableRow(
                children: lengthData
                    .map((text) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[800],
                              fontWeight: text == 'Length'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSizeSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.straighten,
              color: Color(0xFFBB694A),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Size',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sizes.map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFBB694A)
                      : (isDark ? Colors.grey[800] : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFBB694A)
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFBB694A).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelection(bool isDark) {
    if (widget.product['colors'] == null ||
        (widget.product['colors'] as List).isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.palette,
              color: Color(0xFFBB694A),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.product['variantLabel'] ?? 'Color',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (widget.product['colors'] as List).map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFBB694A)
                      : (isDark ? Colors.grey[800] : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFBB694A)
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFBB694A).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelection(bool isDark) {
    return Row(
      children: [
        const Icon(
          Icons.add_shopping_cart,
          color: Color(0xFFBB694A),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Quantity',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          width: 65,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFBB694A).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<int>(
            value: _selectedQuantity,
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFBB694A),
              size: 16,
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            isExpanded: true,
            items: _quantities.map((quantity) {
              return DropdownMenuItem<int>(
                value: quantity,
                child: Center(
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedQuantity = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          border: Border(
            top: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          color: isDark ? Colors.white : Colors.black,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB694A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFF5F5F5).withValues(alpha: 0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Buy Now',
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

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

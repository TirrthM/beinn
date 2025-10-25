import 'package:flutter/material.dart';
import '../main.dart' as main_app;

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  String _selectedSize = 'M';
  String _selectedColor = 'Black';
  int _selectedQuantity = 1;
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

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
  final List<String> _colors = ['Black', 'White', 'Blue', 'Red', 'Green'];
  final List<int> _quantities = List.generate(10, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

    _rotationController = AnimationController(
      duration: Duration(milliseconds: 2000),
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

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
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
            Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.product['name']} added to cart!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFD2691E),
        duration: Duration(seconds: 2),
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
          content: Row(
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
          duration: Duration(seconds: 2),
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
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Added to wishlist!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Color(0xFFD2691E),
          duration: Duration(seconds: 2),
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
    // Create a list of images - using the main product image multiple times
    // In a real app, you would have multiple images for each product
    List<String> images = [];

    if (widget.product['image'] != null) {
      // Add the main image 3 times to simulate multiple product images
      images.add(widget.product['image'].toString());
      images.add(widget.product['image'].toString());
      images.add(widget.product['image'].toString());
    } else {
      // Fallback placeholder images
      images.add('https://via.placeholder.com/400x400/333333/FFFFFF?text=Product+Image+1');
      images.add('https://via.placeholder.com/400x400/333333/FFFFFF?text=Product+Image+2');
      images.add('https://via.placeholder.com/400x400/333333/FFFFFF?text=Product+Image+3');
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final isInWishlist = main_app.CartManager().isInWishlist(widget.product['id']);
    final images = _getProductImages();

    return Scaffold(
      backgroundColor: Colors.black,
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                        Spacer(),
                        GestureDetector(
                          onTap: _toggleWishlist,
                          child: RotationTransition(
                            turns: _rotationAnimation,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isInWishlist ? Color(0xFFD2691E) : Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  isInWishlist ? Icons.favorite : Icons.favorite_outline,
                                  color: Colors.white,
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
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Images
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(0.0, 0.5, curve: Curves.easeOutCubic),
                          )),
                          child: _buildImageCarousel(images),
                        ),
                        SizedBox(height: 24),
                        // Product Info
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(-1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                                )),
                                child: Text(
                                  widget.product['name'] ?? 'Product Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(-1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                                )),
                                child: Text(
                                  widget.product['price'] ?? '₹0',
                                  style: TextStyle(
                                    color: Color(0xFFD2691E),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              // Size Selection
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                                )),
                                child: _buildSizeSelection(),
                              ),
                              SizedBox(height: 24),
                              // Color Selection
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                                )),
                                child: _buildColorSelection(),
                              ),
                              SizedBox(height: 24),
                              // Quantity Selection
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                                )),
                                child: _buildQuantitySelection(),
                              ),
                              SizedBox(height: 24),
                              // Product Description
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(-1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: Interval(0.65, 0.95, curve: Curves.easeOutCubic),
                                )),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[800]!, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.description,
                                            color: Color(0xFFD2691E),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Description',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        widget.product['description'] ?? 'Premium quality clothing with excellent craftsmanship and attention to detail. Made from high-quality materials for comfort and durability.',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Buttons
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return Column(
      children: [
        Container(
          height: 300,
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
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(images[index]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        ScaleTransition(
          scale: _bounceAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: _currentImageIndex == entry.key ? 24 : 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentImageIndex == entry.key
                      ? Color(0xFFD2691E)
                      : Colors.grey[600],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.straighten,
              color: Color(0xFFD2691E),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Size',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
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
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFD2691E) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Color(0xFFD2691E) : Colors.grey[700]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Color(0xFFD2691E).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette,
              color: Color(0xFFD2691E),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFD2691E) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Color(0xFFD2691E) : Colors.grey[700]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Color(0xFFD2691E).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildQuantitySelection() {
    return Row(
      children: [
        Icon(
          Icons.add_shopping_cart,
          color: Color(0xFFD2691E),
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Quantity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Container(
          width: 65,
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color(0xFFD2691E).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<int>(
            value: _selectedQuantity,
            dropdownColor: Colors.grey[800],
            underline: SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFD2691E),
              size: 16,
            ),
            style: TextStyle(
              color: Colors.white,
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
                      color: Colors.white,
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

  Widget _buildBottomButtons() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Container(
        padding: EdgeInsets.all(20),
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
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
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
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD2691E),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Color(0xFFD2691E).withOpacity(0.3),
                  ),
                  child: Row(
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
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../main.dart' as main_app;

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Function(Product)? onWishlistToggle;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onWishlistToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWishlisted = main_app.CartManager().isInWishlist(product.id);

    return GestureDetector(
      onTap: onTap ?? () => main_app.navigateToProductDetail(context, product.toMap()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!, width: 1),
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(product.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFD2691E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.discount,
                        style: TextStyle(
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
                      onTap: () {
                        if (onWishlistToggle != null) {
                          onWishlistToggle!(product);
                        } else {
                          _toggleWishlist(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_outline,
                          color: isWishlisted ? Color(0xFFD2691E) : Colors.white,
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
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
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
                          product.price,
                          style: TextStyle(
                            color: Color(0xFFD2691E),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.originalPrice,
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

  void _toggleWishlist(BuildContext context) {
    if (main_app.CartManager().isInWishlist(product.id)) {
      main_app.CartManager().removeFromWishlist(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} removed from wishlist',
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
      main_app.CartManager().addToWishlist(product.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to wishlist!',
            style: TextStyle(color: Colors.white),
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
  }
}
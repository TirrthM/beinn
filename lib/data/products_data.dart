import '../models/product.dart';

class ProductsData {
  static final Map<String, List<Product>> _productsByCategory = {
    'T-Shirts': [
      Product(
        id: 'tshirt_1',
        name: 'Premium Cotton T-Shirt',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Black', 'White', 'Navy', 'Gray'],
        description: 'Premium quality cotton t-shirt with comfortable fit. Perfect for casual wear and daily use.',
        details: 'Made from 100% organic cotton. Machine washable. Available in multiple sizes and colors.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_2',
        name: 'Graphic Print T-Shirt',
        price: '₹799',
        originalPrice: '₹1199',
        image: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Black', 'White', 'Gray', 'Navy'],
        description: 'Trendy graphic print t-shirt perfect for casual outings.',
        details: 'High-quality print that won\'t fade. Comfortable cotton blend fabric.',
        category: 'T-Shirts',
      ),
      Product(
        id: 'tshirt_3',
        name: 'V-Neck T-Shirt',
        price: '₹899',
        originalPrice: '₹1299',
        image: 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
        discount: '31% OFF',
        images: [
          'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['White', 'Black', 'Navy', 'Gray'],
        description: 'Classic v-neck t-shirt with a modern fit.',
        details: 'Soft cotton fabric. Perfect for layering or wearing alone.',
        category: 'T-Shirts',
      ),
    ],
    'Hoodies': [
      Product(
        id: 'hoodie_1',
        name: 'Sports Hoodie',
        price: '₹1299',
        originalPrice: '₹1999',
        image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=300&h=300&fit=crop',
        discount: '35% OFF',
        images: [
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Gray', 'Black', 'Navy', 'Red'],
        description: 'Comfortable sports hoodie perfect for workouts and casual wear.',
        details: 'Moisture-wicking fabric. Machine washable. Perfect for active lifestyle.',
        category: 'Hoodies',
      ),
      Product(
        id: 'hoodie_2',
        name: 'Pullover Hoodie',
        price: '₹1599',
        originalPrice: '₹2299',
        image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop',
        discount: '30% OFF',
        images: [
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Black', 'Gray', 'Navy', 'Maroon'],
        description: 'Classic pullover hoodie with kangaroo pocket.',
        details: 'Soft fleece interior. Adjustable drawstring hood.',
        category: 'Hoodies',
      ),
    ],
    'Sweatshirts': [
      Product(
        id: 'sweatshirt_1',
        name: 'Crew Neck Sweatshirt',
        price: '₹1199',
        originalPrice: '₹1799',
        image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1506629905607-d405b7a30db4?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Gray', 'Black', 'Navy', 'Maroon'],
        description: 'Comfortable crew neck sweatshirt perfect for casual wear.',
        details: 'Soft fleece interior. Ribbed cuffs and hem.',
        category: 'Sweatshirts',
      ),
    ],
    'Shirts': [
      Product(
        id: 'shirt_1',
        name: 'Formal White Shirt',
        price: '₹1599',
        originalPrice: '₹2299',
        image: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop',
        discount: '30% OFF',
        images: [
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['White', 'Light Blue', 'Light Pink'],
        description: 'Classic formal shirt perfect for office wear and business meetings.',
        details: 'Premium cotton blend. Wrinkle-resistant. Professional fit.',
        category: 'Shirts',
      ),
      Product(
        id: 'shirt_2',
        name: 'Casual Denim Shirt',
        price: '₹1299',
        originalPrice: '₹1899',
        image: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&h=300&fit=crop',
        discount: '32% OFF',
        images: [
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Blue', 'Light Blue', 'Dark Blue'],
        description: 'Casual denim shirt perfect for weekend outings.',
        details: 'High-quality denim fabric. Classic fit.',
        category: 'Shirts',
      ),
    ],
    'Polo': [
      Product(
        id: 'polo_1',
        name: 'Classic Polo Shirt',
        price: '₹1399',
        originalPrice: '₹1999',
        image: 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=300&h=300&fit=crop',
        discount: '30% OFF',
        images: [
          'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Navy', 'White', 'Black', 'Red'],
        description: 'Classic polo shirt perfect for smart casual occasions.',
        details: 'Premium pique cotton. Ribbed collar and cuffs. Regular fit.',
        category: 'Polo',
      ),
    ],
    'Tank Tops': [
      Product(
        id: 'tank_1',
        name: 'Athletic Tank Top',
        price: '₹599',
        originalPrice: '₹899',
        image: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Black', 'Gray', 'Navy'],
        description: 'Comfortable tank top perfect for gym and casual wear.',
        details: 'Breathable cotton blend. Moisture-wicking. Athletic fit.',
        category: 'Tank Tops',
      ),
    ],
    'Sweatpants': [
      Product(
        id: 'sweatpants_1',
        name: 'Jogger Sweatpants',
        price: '₹1199',
        originalPrice: '₹1799',
        image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1506629905607-d405b7a30db4?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        colors: ['Gray', 'Black', 'Navy', 'Maroon'],
        description: 'Comfortable sweatpants perfect for lounging and light workouts.',
        details: 'Soft fleece interior. Adjustable drawstring. Relaxed fit.',
        category: 'Sweatpants',
      ),
    ],
    'Shorts': [
      Product(
        id: 'shorts_1',
        name: 'Summer Shorts',
        price: '₹799',
        originalPrice: '₹1199',
        image: 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1506629905607-d405b7a30db4?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1555274175-6cbf6f3b137b?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Navy', 'Khaki', 'Black', 'Gray'],
        description: 'Comfortable summer shorts perfect for beach and casual outings.',
        details: 'Lightweight fabric. Quick-dry material. Elastic waistband.',
        category: 'Shorts',
      ),
      Product(
        id: 'shorts_2',
        name: 'Cargo Shorts',
        price: '₹999',
        originalPrice: '₹1499',
        image: 'https://images.unsplash.com/photo-1506629905607-d405b7a30db4?w=300&h=300&fit=crop',
        discount: '33% OFF',
        images: [
          'https://images.unsplash.com/photo-1506629905607-d405b7a30db4?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=300&h=300&fit=crop',
          'https://images.unsplash.com/photo-1555274175-6cbf6f3b137b?w=300&h=300&fit=crop',
        ],
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Khaki', 'Black', 'Olive', 'Navy'],
        description: 'Functional cargo shorts with multiple pockets.',
        details: 'Durable cotton fabric. Multiple utility pockets.',
        category: 'Shorts',
      ),
    ],
  };

  static List<Product> getProductsByCategory(String categoryName) {
    return _productsByCategory[categoryName] ?? [];
  }

  static List<Product> getAllProducts() {
    List<Product> allProducts = [];
    _productsByCategory.values.forEach((products) {
      allProducts.addAll(products);
    });
    return allProducts;
  }

  static Product? getProductById(String id) {
    for (var products in _productsByCategory.values) {
      try {
        return products.firstWhere((product) => product.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  static List<String> getAvailableCategories() {
    return _productsByCategory.keys.toList();
  }
}
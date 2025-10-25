class Product {
  final String id;
  final String name;
  final String price;
  final String originalPrice;
  final String image;
  final String discount;
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final String description;
  final String details;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.discount,
    required this.images,
    required this.sizes,
    required this.colors,
    required this.description,
    required this.details,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'image': image,
      'discount': discount,
      'images': images,
      'sizes': sizes,
      'colors': colors,
      'description': description,
      'details': details,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      originalPrice: map['originalPrice'] ?? '',
      image: map['image'] ?? '',
      discount: map['discount'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      description: map['description'] ?? '',
      details: map['details'] ?? '',
      category: map['category'] ?? '',
    );
  }
}
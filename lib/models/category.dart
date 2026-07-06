class Category {
  final String name;
  final String type;
  final String image;
  final String description;

  Category({
    required this.name,
    required this.type,
    required this.image,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'image': image,
      'description': description,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      image: map['image'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

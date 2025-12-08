
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category; // <--- Added this field

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category, // <--- Added this to constructor
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      // Safely handle price whether it's an int or double
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0),
      // Handle potential field name mismatch (image vs imageUrl)
      imageUrl: data['image'] ?? data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '', // <--- Now properly fetching category
    );
  }
}

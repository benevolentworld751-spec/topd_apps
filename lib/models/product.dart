class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'],
      description: data['description'] ?? '',
    );
  }
}

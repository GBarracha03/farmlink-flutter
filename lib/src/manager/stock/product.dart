class Product {
  final String? id;
  final String? userId;
  final String? name;
  final double? quantity;
  final String? unity;
  final String? imageUrl;

  Product({
    this.id,
    required this.userId,
    this.name,
    this.quantity,
    this.unity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'quantity': quantity,
      'unity': unity,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      userId: map['userId'],
      name: map['name'],
      quantity: map['quantity']?.toDouble(),
      unity: map['unity'],
      imageUrl: map['imageUrl'],
    );
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    double? quantity,
    String? unity,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unity: unity ?? this.unity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

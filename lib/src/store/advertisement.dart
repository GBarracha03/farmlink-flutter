import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String? id;
  final String userId;
  final String productId;
  final String advertisementName;
  final String category;
  final String? description;
  final String? imageUrl;
  final List<String> deliveryOptions;
  final double latitude;
  final double longitude;
  final double quantity;
  final String unity;
  final double price;
  final DateTime createdAt;

  Advertisement({
    this.id,
    required this.userId,
    required this.productId,
    required this.advertisementName,
    required this.category,
    this.description,
    this.imageUrl,
    required this.deliveryOptions,
    required this.latitude,
    required this.longitude,
    required this.quantity,
    required this.unity,
    required this.price,
    required this.createdAt,
  });

  Advertisement copyWith({
    String? id,
    String? userId,
    String? productId,
    String? advertisementName,
    String? category,
    String? description,
    String? imageUrl,
    List<String>? deliveryOptions,
    double? latitude,
    double? longitude,
    double? quantity,
    String? unity,
    double? price,
    DateTime? createdAt,
  }) {
    return Advertisement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      advertisementName: advertisementName ?? this.advertisementName,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      quantity: quantity ?? this.quantity,
      unity: unity ?? this.unity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Advertisement.fromMap(String id, Map<String, dynamic> map) {
    return Advertisement(
      id: id,
      userId: map['userId'],
      productId: map['productId'],
      advertisementName: map['advertisementName'],
      category: map['category'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      deliveryOptions: List<String>.from(map['deliveryOptions']),
      longitude: map['longitude'],
      latitude: map['latitude'],
      quantity: map['quantity']?.toDouble(),
      unity: map['unity'],
      price: map['price']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'advertisementName': advertisementName,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'deliveryOptions': deliveryOptions,
      'longitude': longitude,
      'latitude': latitude,
      'quantity': quantity,
      'unity': unity,
      'price': price,
      'createdAt': createdAt,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String? id;
  final String clientId;
  final String producerId;

  final String advertisementId;
  final String advertisementName;

  final String address;

  final String deliveryOption;
  final String status;
  final DateTime createdAt;

  final double? price;
  final double? adLat;
  final double? adLng;

  Order({
    this.id,
    required this.clientId,
    required this.producerId,

    required this.advertisementId,
    required this.advertisementName,

    required this.address,

    required this.deliveryOption,
    required this.status,
    required this.createdAt,

    required this.price,
    required this.adLat,
    required this.adLng,
  });

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      id: id,
      clientId: map['clientId'],
      producerId: map['producerId'],

      advertisementId: map['advertisementId'],
      advertisementName: map['advertisementName'],

      address: map['address'],

      deliveryOption: map['deliveryOption'],
      status: map['status'] ?? 'pendente',
      createdAt: (map['createdAt'] as Timestamp).toDate(),

      price: map['price']?.toDouble(),
      adLat: map['adLat']?.toDouble(),
      adLng: map['adLng']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'producerId': producerId,

      'advertisementId': advertisementId,
      'advertisementName': advertisementName,

      'address': address,

      'deliveryOption': deliveryOption,
      'status': status,
      'createdAt': createdAt,

      'price': price,
      'adLat': adLat,
      'adLng': adLng,
    };
  }
}

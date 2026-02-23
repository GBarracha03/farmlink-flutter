import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:projeto/src/orders/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addOrder(Order order) async {
    await _firestore.collection('orders').add(order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  Stream<List<Order>> getOrdersByProducer(String producerId, {String? status}) {
    Query query = _firestore
        .collection('orders')
        .where('producerId', isEqualTo: producerId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Order.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Stream<List<Order>> getOrdersByClient(String clientId) {
    return _firestore
        .collection('orders')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Order.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }
}

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getAvailableOrders() {
    _log('WATCH available orders (status=ready, no rider)');
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'ready')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((order) => order.riderId == null || order.riderId!.isEmpty)
          .toList();
      _log('WATCH available orders -> ${orders.length} results');
      return orders;
    });
  }

  Stream<List<OrderModel>> getRiderOrders(String riderId) {
    _log('WATCH rider orders (riderId=$riderId)');
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _log('WATCH rider orders -> ${snapshot.docs.length} results');
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<OrderModel>> getActiveDeliveries(String riderId) {
    _log('WATCH active deliveries (riderId=$riderId)');
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'picked_up')
        .snapshots()
        .map((snapshot) {
      _log('WATCH active deliveries -> ${snapshot.docs.length} results');
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    _log('WATCH order/$orderId');
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      _log('WATCH order/$orderId -> exists: ${doc.exists}');
      return doc.exists ? OrderModel.fromFirestore(doc) : null;
    });
  }

  Future<void> acceptOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    _log('ACCEPT order/$orderId -> rider: $riderId');
    await _firestore.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'status': 'picked_up',
      'pickedUpAt': Timestamp.now(),
    });

    await _firestore.collection('riders').doc(riderId).update({
      'isOnDelivery': true,
    });
    _log('ACCEPT order/$orderId -> SUCCESS');
  }

  Future<void> completeDelivery(String orderId, String riderId) async {
    _log('COMPLETE order/$orderId');
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final deliveryFee = (orderDoc.data()?['deliveryFee'] ?? 0).toDouble();

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'deliveredAt': Timestamp.now(),
    });

    await _firestore.collection('riders').doc(riderId).update({
      'isOnDelivery': false,
      'completedDeliveries': FieldValue.increment(1),
      'totalEarnings': FieldValue.increment(deliveryFee),
    });
    _log('COMPLETE order/$orderId -> SUCCESS');
  }

  Future<List<OrderModel>> getCompletedOrders(String riderId) async {
    _log('GET completed orders (riderId=$riderId)');
    final snapshot = await _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true)
        .get();
    _log('GET completed orders -> ${snapshot.docs.length} results');
    return snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();
  }

  void _log(String message) {
    dev.log('[FIRESTORE] $message', name: 'KaliRider');
  }
}

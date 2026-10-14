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
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((order) => order.riderId == null || order.riderId!.isEmpty)
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _log('WATCH available orders -> ${orders.length} results');
      return orders;
    });
  }

  Stream<List<OrderModel>> getRiderOrders(String riderId) {
    _log('WATCH rider orders (riderId=$riderId)');
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _log('WATCH rider orders -> ${orders.length} results');
      return orders;
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

    // Create notification for the rider
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final vendorName = orderDoc.data()?['vendorName'] ?? 'Unknown';
    await _firestore.collection('notifications').add({
      'riderId': riderId,
      'title': 'Order Accepted',
      'body': 'You accepted an order from $vendorName. Head to the store for pickup!',
      'type': 'order_update',
      'orderId': orderId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });

    _log('ACCEPT order/$orderId -> SUCCESS');
  }

  /// Verify delivery PIN before completing delivery.
  /// Returns true if PIN matches, false otherwise.
  Future<bool> verifyDeliveryPin(String orderId, String enteredPin) async {
    _log('VERIFY PIN order/$orderId');
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final storedPin = orderDoc.data()?['deliveryPin'] as String?;
    if (storedPin == null || storedPin.isEmpty) {
      // No PIN set on order — allow delivery (backwards compatible)
      _log('VERIFY PIN order/$orderId -> no PIN set, allowing');
      return true;
    }
    final matches = storedPin == enteredPin;
    _log('VERIFY PIN order/$orderId -> ${matches ? 'MATCH' : 'MISMATCH'}');
    return matches;
  }

  Future<void> completeDelivery(String orderId, String riderId) async {
    _log('COMPLETE order/$orderId');
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data();
    final serviceFee = (orderData?['serviceFee'] ?? 0).toDouble();
    final deliveryFee = (orderData?['deliveryFee'] ?? 0).toDouble();
    // Rider earns the service fee; fallback to delivery fee if no service fee
    final riderEarning = serviceFee > 0 ? serviceFee : deliveryFee;
    final vendorName = orderData?['vendorName'] ?? 'Unknown';

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'deliveredAt': Timestamp.now(),
    });

    await _firestore.collection('riders').doc(riderId).update({
      'isOnDelivery': false,
      'completedDeliveries': FieldValue.increment(1),
      'totalEarnings': FieldValue.increment(riderEarning),
    });

    // Create earning notification
    await _firestore.collection('notifications').add({
      'riderId': riderId,
      'title': 'Delivery Complete!',
      'body': 'You earned ${_formatNaira(riderEarning)} for delivering from $vendorName.',
      'type': 'earning',
      'orderId': orderId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });

    _log('COMPLETE order/$orderId -> SUCCESS (earned: $riderEarning)');
  }

  Future<List<OrderModel>> getCompletedOrders(String riderId) async {
    _log('GET completed orders (riderId=$riderId)');
    final snapshot = await _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'delivered')
        .get();
    final orders = snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();
    orders.sort((a, b) => (b.deliveredAt ?? b.createdAt).compareTo(a.deliveredAt ?? a.createdAt));
    _log('GET completed orders -> ${orders.length} results');
    return orders;
  }

  String _formatNaira(double amount) {
    return '\u20A6${amount.toStringAsFixed(0)}';
  }

  void _log(String message) {
    dev.log('[FIRESTORE] $message', name: 'KaliRider');
  }
}

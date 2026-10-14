import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotifications(String riderId) {
    _log('WATCH notifications (riderId=$riderId)');
    return _firestore
        .collection('notifications')
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      _log('WATCH notifications -> ${snapshot.docs.length} results');
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<int> getUnreadCount(String riderId) {
    return _firestore
        .collection('notifications')
        .where('riderId', isEqualTo: riderId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    _log('MARK READ notification/$notificationId');
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String riderId) async {
    _log('MARK ALL READ (riderId=$riderId)');
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('riderId', isEqualTo: riderId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String riderId,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    _log('CREATE notification for rider/$riderId: $title');
    await _firestore.collection('notifications').add({
      'riderId': riderId,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  void _log(String message) {
    dev.log('[FIRESTORE] $message', name: 'KaliRider');
  }
}
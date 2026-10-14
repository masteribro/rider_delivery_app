import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String riderId;
  final String title;
  final String body;
  final String type; // 'new_order', 'order_update', 'earning', 'system'
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.riderId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      riderId: data['riderId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      orderId: data['orderId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
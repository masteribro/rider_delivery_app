import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String address;
  final String vehicleType;
  final String plateNumber;
  final bool isOnline;
  final bool isOnDelivery;
  final double totalEarnings;
  final int completedDeliveries;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;

  const RiderModel({
    required this.uid,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photoUrl,
    this.address = '',
    this.vehicleType = 'motorcycle',
    this.plateNumber = '',
    this.isOnline = false,
    this.isOnDelivery = false,
    this.totalEarnings = 0,
    this.completedDeliveries = 0,
    this.rating = 0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  factory RiderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RiderModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      address: data['address'] ?? '',
      vehicleType: data['vehicleType'] ?? 'motorcycle',
      plateNumber: data['plateNumber'] ?? '',
      isOnline: data['isOnline'] ?? false,
      isOnDelivery: data['isOnDelivery'] ?? false,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      completedDeliveries: data['completedDeliveries'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'address': address,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'isOnline': isOnline,
      'isOnDelivery': isOnDelivery,
      'totalEarnings': totalEarnings,
      'completedDeliveries': completedDeliveries,
      'rating': rating,
      'ratingCount': ratingCount,
      'accountType': 'rider',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RiderModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    String? vehicleType,
    String? plateNumber,
    bool? isOnline,
    bool? isOnDelivery,
    double? totalEarnings,
    int? completedDeliveries,
    double? rating,
    int? ratingCount,
  }) {
    return RiderModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      isOnline: isOnline ?? this.isOnline,
      isOnDelivery: isOnDelivery ?? this.isOnDelivery,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt,
    );
  }
}

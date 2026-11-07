import 'package:cloud_firestore/cloud_firestore.dart';

class RiderDocument {
  final String id;
  final String type; // 'id_card', 'drivers_license', 'vehicle_registration'
  final String imageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime uploadedAt;

  const RiderDocument({
    required this.id,
    required this.type,
    required this.imageUrl,
    this.status = 'pending',
    this.rejectionReason,
    required this.uploadedAt,
  });

  factory RiderDocument.fromMap(Map<String, dynamic> map) {
    return RiderDocument(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'imageUrl': imageUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'id_card':
        return 'Government ID';
      case 'drivers_license':
        return "Driver's License";
      case 'vehicle_registration':
        return 'Vehicle Registration';
      default:
        return type;
    }
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

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
  final String verificationStatus; // 'unverified', 'pending', 'verified', 'rejected'
  final List<RiderDocument> documents;
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
    this.verificationStatus = 'unverified',
    this.documents = const [],
    required this.createdAt,
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get isVerificationPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isUnverified => verificationStatus == 'unverified';

  bool get hasAllDocuments {
    final types = documents.map((d) => d.type).toSet();
    return types.contains('id_card') &&
        types.contains('drivers_license') &&
        types.contains('vehicle_registration');
  }

  RiderDocument? getDocument(String type) {
    try {
      return documents.firstWhere((d) => d.type == type);
    } catch (_) {
      return null;
    }
  }

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
      verificationStatus: data['verificationStatus'] ?? 'unverified',
      documents: (data['documents'] as List<dynamic>?)
              ?.map((d) => RiderDocument.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
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
      'verificationStatus': verificationStatus,
      'documents': documents.map((d) => d.toMap()).toList(),
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
    String? verificationStatus,
    List<RiderDocument>? documents,
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
      verificationStatus: verificationStatus ?? this.verificationStatus,
      documents: documents ?? this.documents,
      createdAt: createdAt,
    );
  }
}

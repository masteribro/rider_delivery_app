import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/rider_model.dart';

class DocumentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RiderDocument> uploadDocument({
    required String riderId,
    required String type,
    required File imageFile,
  }) async {
    // Get current documents
    final riderDoc = await _firestore.collection('riders').doc(riderId).get();
    final data = riderDoc.data() ?? {};
    final existingDocs = (data['documents'] as List<dynamic>?)
            ?.map((d) => RiderDocument.fromMap(d as Map<String, dynamic>))
            .toList() ??
        [];

    final docId = const Uuid().v4();

    // Simulate upload delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 1500));

    // Use local file path as the image reference (prototype — no cloud storage needed)
    final doc = RiderDocument(
      id: docId,
      type: type,
      imageUrl: imageFile.path,
      status: 'approved',
      uploadedAt: DateTime.now(),
    );

    // Remove old document of same type
    existingDocs.removeWhere((d) => d.type == type);
    existingDocs.add(doc);

    // Determine verification status
    final allTypes = existingDocs.map((d) => d.type).toSet();
    final hasAll = allTypes.contains('id_card') &&
        allTypes.contains('drivers_license') &&
        allTypes.contains('vehicle_registration');
    // Auto-approve: no admin dashboard yet
    final newStatus = hasAll ? 'verified' : 'unverified';

    await _firestore.collection('riders').doc(riderId).update({
      'documents': existingDocs.map((d) => d.toMap()).toList(),
      'verificationStatus': newStatus,
    });

    return doc;
  }

  Future<void> deleteDocument({
    required String riderId,
    required String documentId,
  }) async {
    final riderDoc = await _firestore.collection('riders').doc(riderId).get();
    final data = riderDoc.data() ?? {};
    final existingDocs = (data['documents'] as List<dynamic>?)
            ?.map((d) => RiderDocument.fromMap(d as Map<String, dynamic>))
            .toList() ??
        [];

    existingDocs.removeWhere((d) => d.id == documentId);

    await _firestore.collection('riders').doc(riderId).update({
      'documents': existingDocs.map((d) => d.toMap()).toList(),
      'verificationStatus': 'unverified',
    });
  }
}

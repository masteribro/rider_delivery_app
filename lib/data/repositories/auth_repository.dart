import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _log('AUTH', 'signUpWithEmail -> $email');
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _log('AUTH', 'signUp SUCCESS -> uid: ${result.user?.uid}');
    return result;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _log('AUTH', 'signInWithEmail -> $email');
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _log('AUTH', 'signIn SUCCESS -> uid: ${result.user?.uid}');
    return result;
  }

  Future<void> sendPasswordReset(String email) async {
    _log('AUTH', 'sendPasswordReset -> $email');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<RiderModel?> getRiderProfile(String uid) async {
    _log('FIRESTORE', 'GET riders/$uid');
    final doc = await _firestore.collection('riders').doc(uid).get();
    _log('FIRESTORE', 'GET riders/$uid -> exists: ${doc.exists}');
    if (doc.exists) {
      return RiderModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createRiderProfile(RiderModel rider) async {
    _log('FIRESTORE', 'SET riders/${rider.uid}');
    await _firestore.collection('riders').doc(rider.uid).set(rider.toMap());
    _log('FIRESTORE', 'SET riders/${rider.uid} -> SUCCESS');
  }

  Future<void> updateRiderProfile(String uid, Map<String, dynamic> data) async {
    _log('FIRESTORE', 'UPDATE riders/$uid');
    await _firestore.collection('riders').doc(uid).update(data);
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    _log('FIRESTORE', 'SET riders/$uid -> isOnline: $isOnline');
    await _firestore.collection('riders').doc(uid).update({
      'isOnline': isOnline,
    });
  }

  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await setOnlineStatus(uid, false);
    }
    await _auth.signOut();
    _log('AUTH', 'signOut -> SUCCESS');
  }

  void _log(String tag, String message) {
    dev.log('[$tag] $message', name: 'KaliRider');
  }
}

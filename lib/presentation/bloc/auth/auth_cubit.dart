import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/rider_model.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepo;

  AuthCubit(this._authRepo) : super(AuthInitial());

  RiderModel? _riderProfile;
  RiderModel? get riderProfile => _riderProfile;

  Future<void> checkAuthStatus() async {
    final user = _authRepo.currentUser;
    if (user != null) {
      final profile = await _authRepo.getRiderProfile(user.uid);
      if (profile != null && profile.name.isNotEmpty) {
        _riderProfile = profile;
        emit(AuthAuthenticated(profile));
      } else {
        emit(AuthNeedsProfile());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepo.signUpWithEmail(
        email: email,
        password: password,
      );
      // Don't create rider profile yet - redirect to setup screen
      emit(AuthNeedsProfile());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepo.signInWithEmail(
        email: email,
        password: password,
      );
      final user = _authRepo.currentUser!;
      final profile = await _authRepo.getRiderProfile(user.uid);
      if (profile != null && profile.name.isNotEmpty) {
        _riderProfile = profile;
        emit(AuthAuthenticated(profile));
      } else {
        emit(AuthNeedsProfile());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authRepo.sendPasswordReset(email);
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> completeProfile({
    required String name,
    required String phone,
    required String address,
    required String vehicleType,
    required String plateNumber,
  }) async {
    emit(AuthLoading());
    try {
      final user = _authRepo.currentUser!;
      final rider = RiderModel(
        uid: user.uid,
        name: name,
        email: user.email ?? '',
        phone: phone,
        address: address,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        createdAt: DateTime.now(),
      );
      await _authRepo.createRiderProfile(rider);
      _riderProfile = rider;
      emit(AuthAuthenticated(rider));
    } catch (e) {
      emit(AuthError('Failed to save profile'));
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? vehicleType,
    String? plateNumber,
  }) async {
    if (_riderProfile == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (vehicleType != null) updates['vehicleType'] = vehicleType;
      if (plateNumber != null) updates['plateNumber'] = plateNumber;
      await _authRepo.updateRiderProfile(_riderProfile!.uid, updates);
      _riderProfile = _riderProfile!.copyWith(
        name: name,
        phone: phone,
        address: address,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
      emit(AuthAuthenticated(_riderProfile!));
    } catch (e) {
      emit(AuthError('Failed to update profile'));
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (_riderProfile == null) return;
    try {
      final newStatus = !_riderProfile!.isOnline;
      await _authRepo.setOnlineStatus(_riderProfile!.uid, newStatus);
      _riderProfile = _riderProfile!.copyWith(isOnline: newStatus);
      emit(AuthAuthenticated(_riderProfile!));
    } catch (e) {
      emit(AuthError('Failed to update status'));
    }
  }

  Future<void> refreshProfile() async {
    final user = _authRepo.currentUser;
    if (user != null) {
      final profile = await _authRepo.getRiderProfile(user.uid);
      if (profile != null) {
        _riderProfile = profile;
        emit(AuthAuthenticated(profile));
      }
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _riderProfile = null;
    emit(AuthUnauthenticated());
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

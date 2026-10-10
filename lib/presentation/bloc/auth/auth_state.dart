part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthNeedsProfile extends AuthState {}

class AuthAuthenticated extends AuthState {
  final RiderModel rider;
  const AuthAuthenticated(this.rider);
  @override
  List<Object?> get props => [rider.uid, rider.name, rider.email];
}

class AuthUnauthenticated extends AuthState {}

class AuthPasswordResetSent extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

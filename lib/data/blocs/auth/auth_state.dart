import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,
  loading,
  initializing,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final List<String> roles;
  final String? userId;
  final String? username;
  final String? errorMessage;
  final bool isLandlord;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.roles = const [],
    this.userId,
    this.username,
    this.errorMessage,
    this.isLandlord = false,
  });

  factory AuthState.initial() => const AuthState(
        status: AuthStatus.initial,
      );

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    List<String>? roles,
    String? userId,
    String? username,
    String? errorMessage,
    bool? isLandlord,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      roles: roles ?? this.roles,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
      isLandlord: isLandlord ?? this.isLandlord,
    );
  }

  @override
  List<Object?> get props => [status, token, roles, userId, username, errorMessage, isLandlord];
}

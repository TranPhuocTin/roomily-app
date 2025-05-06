import 'package:roomily/data/models/login_request.dart';
import 'package:roomily/data/models/login_response.dart';
import 'package:roomily/data/models/register_request.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest loginRequest);

  /// Registers a new user
  Future<bool> register(RegisterRequest registerRequest);

  Future<void> logout();

  /// Saves the user token to secure storage
  Future<void> saveUserToken(String token);

  /// Saves the user role to storage
  Future<void> saveUserRole(List<String> roles);

  /// Saves the user ID to storage
  Future<void> saveUserId(String userId);

  /// Saves the username to storage
  Future<void> saveUsername(String username);

  /// Clears all saved authentication data (for logout)
  Future<void> clearAuthData();

  /// Checks if the user is authenticated
  Future<bool> isAuthenticated();

  /// Gets the user's role
  Future<List<String>> getUserRoles();

  /// Gets the user's token
  Future<String?> getUserToken();

  /// Gets the user's ID
  Future<String?> getUserId();

  /// Gets the username
  Future<String?> getUsername();
}

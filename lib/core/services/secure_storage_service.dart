import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service for securely storing sensitive data like authentication tokens
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  // Constants for storage keys
  static const String TOKEN_KEY = 'auth_token';
  static const String ROLES_KEY = 'user_roles';
  static const String USER_ID_KEY = 'user_id';
  static const String USERNAME_KEY = 'username';

  SecureStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? FlutterSecureStorage();

  /// Saves a string value securely
  Future<void> setString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Retrieves a string value
  Future<String?> getString(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Saves a list of strings securely
  Future<void> setStringList(String key, List<String> value) async {
    final String encodedValue = json.encode(value);
    await _secureStorage.write(key: key, value: encodedValue);
  }

  /// Retrieves a list of strings
  Future<List<String>> getStringList(String key) async {
    final String? encodedValue = await _secureStorage.read(key: key);
    if (encodedValue == null) {
      return [];
    }
    return List<String>.from(json.decode(encodedValue));
  }

  /// Removes a value
  Future<void> remove(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clears all values
  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }

  /// Checks if a key exists
  Future<bool> containsKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }

  // Authentication specific methods
  
  /// Saves the authentication token
  Future<void> saveToken(String token) async {
    await setString(TOKEN_KEY, token);
  }

  /// Gets the authentication token
  Future<String?> getToken() async {
    return await getString(TOKEN_KEY);
  }

  /// Saves the user roles
  Future<void> saveRoles(List<String> roles) async {
    await setStringList(ROLES_KEY, roles);
  }

  /// Gets the user roles
  Future<List<String>> getRoles() async {
    return await getStringList(ROLES_KEY);
  }

  /// Saves the user ID
  Future<void> saveUserId(String userId) async {
    await setString(USER_ID_KEY, userId);
  }

  /// Gets the user ID
  Future<String?> getUserId() async {
    return await getString(USER_ID_KEY);
  }

  /// Saves the username
  Future<void> saveUsername(String username) async {
    await setString(USERNAME_KEY, username);
  }

  /// Gets the username
  Future<String?> getUsername() async {
    return await getString(USERNAME_KEY);
  }

  /// Clears all authentication data (for logout)
  Future<void> clearAuthData() async {
    await remove(TOKEN_KEY);
    await remove(ROLES_KEY);
    await remove(USER_ID_KEY);
    await remove(USERNAME_KEY);
  }

  /// Checks if the user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
} 
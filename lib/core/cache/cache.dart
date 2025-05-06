import 'dart:convert';
import 'package:roomily/data/models/models.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract class Cache {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value);
  Future<void> remove(String key);
  Future<void> clear();
}

class PersistentCache implements Cache {
  final DefaultCacheManager _cacheManager;
  
  PersistentCache() : _cacheManager = DefaultCacheManager();

  @override
  Future<T?> get<T>(String key) async {
    final file = await _cacheManager.getFileFromCache(key);
    if (file == null) return null;

    try {
      final jsonStr = await file.file.readAsString();
      final json = jsonDecode(jsonStr);
      
      if (T == Room) {
        return Room.fromJson(json) as T;
      }
      // Add more type checks for other models here
      
      return json as T;
    } catch (e) {
      await _cacheManager.removeFile(key);
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T value) async {
    final jsonStr = jsonEncode(value);
    await _cacheManager.putFile(
      key,
      utf8.encode(jsonStr),
      maxAge: const Duration(days: 7), // Cache for 7 days
    );
  }

  @override
  Future<void> remove(String key) async {
    await _cacheManager.removeFile(key);
  }

  @override
  Future<void> clear() async {
    await _cacheManager.emptyCache();
  }
}

// Keep InMemoryCache for testing purposes
class InMemoryCache implements Cache {
  final Map<String, dynamic> _cache = {};

  @override
  Future<T?> get<T>(String key) async {
    return _cache[key] as T?;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _cache[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }
} 
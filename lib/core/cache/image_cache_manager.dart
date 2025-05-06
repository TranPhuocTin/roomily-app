import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/painting.dart';

class ImageCacheManager extends CacheManager {
  static const key = 'roomImageCache_v1';
  
  static final ImageCacheManager _instance = ImageCacheManager._();
  factory ImageCacheManager() => _instance;

  ImageCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
  ));

  Future<void> preloadImage(String url) async {
    await downloadFile(url);
  }

  Future<void> removeImage(String url) async {
    await removeFile(url);
  }

  Future<void> clearRoomCache(String roomId) async {
    print('🗑️ Clearing cache for room: $roomId');
    await emptyCache();
  }

  static Future<void> clearCache() async {
    await _instance.emptyCache();
  }
}

// Cache manager cho room thumbnails (ảnh nhỏ)
class RoomThumbnailCacheManager extends CacheManager {
  static const key = 'roomThumbnailCache_v2';
  
  static final RoomThumbnailCacheManager _instance = RoomThumbnailCacheManager._();
  factory RoomThumbnailCacheManager() => _instance;

  RoomThumbnailCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100,
  ));

  static Future<void> clearCache() async {
    await _instance.emptyCache();
  }
}

// Cache manager cho user avatars
class AvatarCacheManager extends CacheManager {
  static const key = 'avatarCache_v2';
  
  static final AvatarCacheManager _instance = AvatarCacheManager._();
  factory AvatarCacheManager() => _instance;

  AvatarCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 50,
  ));

  @override
  Future<String> getFilePath() async {
    return key;
  }

  static Future<void> clearCache() async {
    await _instance.emptyCache();
  }
}

// Utility class để quản lý tất cả cache
class ImageCacheService {
  static Future<void> clearAllCaches() async {
    print('🗑️ Clearing all image caches...');
    await ImageCacheManager().emptyCache();
    await RoomThumbnailCacheManager().emptyCache();
    await AvatarCacheManager().emptyCache();
    print('✅ All caches cleared');
  }
}

// Utility function to clear all caches
Future<void> clearAllImageCaches() async {
  await ImageCacheManager.clearCache();
  await RoomThumbnailCacheManager.clearCache();
  await AvatarCacheManager.clearCache();
  // Clear Flutter's internal image cache
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
} 
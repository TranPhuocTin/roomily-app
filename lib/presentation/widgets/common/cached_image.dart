import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:roomily/core/cache/image_cache_manager.dart' as app_cache;
import 'package:roomily/core/config/app_colors.dart';

enum ImageType {
  room,
  thumbnail,
  avatar
}

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageType type;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.type = ImageType.room,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('\n🔄 Starting image load process for: $imageUrl');
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheManager: _getCacheManager(),
        placeholder: (context, url) => placeholder ?? Container(
          color: AppColors.grey100,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          print('❌ Error loading image: $url');
          print('❌ Error details: $error');
          return errorWidget ?? Container(
            color: AppColors.grey100,
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: AppColors.grey400,
              ),
            ),
          );
        },
        imageBuilder: (context, imageProvider) {
          print('✅ Successfully loaded image');
          _logImageSource();
          return Image(image: imageProvider, fit: fit);
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _logImageSource() {
    _getCacheManager().getFileFromCache(imageUrl).then((cacheFile) {
      if (cacheFile != null) {
        final age = DateTime.now().difference(cacheFile.validTill);
        print('🔍 Source: Loaded from cache (${_formatDuration(age)})');
      } else {
        print('🔍 Source: Downloaded from network');
      }
    });
  }

  CacheManager _getCacheManager() {
    final cacheManager = switch (type) {
      ImageType.room => app_cache.ImageCacheManager(),
      ImageType.thumbnail => app_cache.RoomThumbnailCacheManager(),
      ImageType.avatar => app_cache.AvatarCacheManager(),
    };

    // Debug cache status
    cacheManager.getFileFromCache(imageUrl).then((cacheFile) {
      if (cacheFile != null) {
        final age = DateTime.now().difference(cacheFile.validTill);
        print('📂 Cache status: Found in cache');
        print('📅 Cache validity: ${_formatDuration(age)} until expiration');
      } else {
        print('📂 Cache status: Not found in cache');
      }
    });

    return cacheManager;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '${-duration.inDays}d ${-duration.inHours % 24}h ${-duration.inMinutes % 60}m remaining';
    } else {
      return 'Expired ${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m ago';
    }
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: AppColors.grey100,
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: AppColors.grey400,
        ),
      ),
    );
  }
} 
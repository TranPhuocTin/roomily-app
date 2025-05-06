import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/recommended_tag.dart';
import 'package:roomily/data/repositories/tag_repository.dart';
import 'package:roomily/core/utils/result.dart';

/// Service pour gérer les tags/tiện ích
class TagService {
  final TagRepository _tagRepository;
  List<RoomTag>? _cachedTags;

  TagService({TagRepository? tagRepository})
      : _tagRepository = tagRepository ?? GetIt.instance<TagRepository>();

  /// Récupère tous les tags, en utilisant le cache si disponible
  Future<List<RoomTag>> getAllTags({bool forceRefresh = false}) async {
    // Si le cache est disponible et qu'on ne force pas le rafraîchissement, retourner le cache
    if (_cachedTags != null && !forceRefresh) {
      return _cachedTags!;
    }

    // Sinon, récupérer les tags depuis le repository
    final result = await _tagRepository.getAllTags();
    
    switch (result) {
      case Success(data: final tags):
        _cachedTags = tags;
        return tags;
      case Failure(message: final message):
        // En cas d'erreur, retourner une liste vide ou le cache si disponible
        return _cachedTags ?? [];
    }
  }

  /// Fetch recommended tags based on location coordinates
  Future<List<RecommendedTag>> getRecommendedTags({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _tagRepository.getRecommendedTags(
      latitude: latitude,
      longitude: longitude,
    );
    
    switch (result) {
      case Success(data: final tags):
        return tags;
      case Failure(message: final message):
        // Return empty list on error
        return [];
    }
  }

  /// Récupère un tag par son ID
  RoomTag? getTagById(String id) {
    if (_cachedTags == null) return null;
    
    try {
      return _cachedTags!.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Convertit une liste d'IDs de tags en liste de RoomTag
  List<RoomTag> getTagsByIds(List<String> ids) {
    if (_cachedTags == null) return [];
    
    return _cachedTags!
        .where((tag) => ids.contains(tag.id))
        .toList();
  }

  /// Vérifie si les tags sont déjà chargés
  bool get isTagsLoaded => _cachedTags != null;
} 
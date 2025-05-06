import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/tag/tag_state.dart';
import 'package:roomily/data/repositories/tag_repository.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/core/services/tag_service.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/room.dart';

class TagCubit extends Cubit<TagState> {
  final TagRepository _tagRepository;
  final TagService _tagService;

  TagCubit({required TagRepository tagRepository})
      : _tagRepository = tagRepository,
        _tagService = GetIt.instance<TagService>(),
        super(const TagState());

  Future<void> getAllTags() async {
    emit(state.copyWith(status: TagStatus.loading));

    final result = await _tagRepository.getAllTags();

    switch (result) {
      case Success(data: final tags):
        emit(
          state.copyWith(
            tags: tags,
            status: TagStatus.loaded,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: TagStatus.error,
            errorMessage: message,
          ),
        );
    }
  }

  Future<void> getRecommendedTags({
    required double latitude,
    required double longitude,
  }) async {
    final tags = await _tagService.getRecommendedTags(
      latitude: latitude,
      longitude: longitude,
    );

    emit(state.copyWith(recommendedTags: tags));
  }
  
  // Trả về danh sách ID của các tag được đề xuất dựa trên vị trí
  List<String> getRecommendedTagIds() {
    final List<String> recommendedTagNames = state.recommendedTags.map((rt) => rt.tagName).toList();
    
    // Tìm các tag có tên trùng với recommended tags
    final List<String> tagIds = state.tags
        .where((tag) => recommendedTagNames.contains(tag.name))
        .map((tag) => tag.id)
        .toList();
        
    return tagIds;
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/find_partner_post_detail.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';

part 'find_partner_post_detail_state.dart';

class FindPartnerPostDetailCubit extends Cubit<FindPartnerPostDetailState> {
  final FindPartnerRepository findPartnerRepository;

  FindPartnerPostDetailCubit({
    required this.findPartnerRepository,
  }) : super(FindPartnerPostDetailInitial());

  Future<void> getFindPartnerPostDetail(String postId) async {
    try {
      emit(FindPartnerPostDetailLoading());
      final postDetail = await findPartnerRepository.getFindPartnerPostDetail(postId);
      emit(FindPartnerPostDetailLoaded(postDetail: postDetail));
    } catch (e) {
      emit(FindPartnerPostDetailError(message: e.toString()));
    }
  }
} 
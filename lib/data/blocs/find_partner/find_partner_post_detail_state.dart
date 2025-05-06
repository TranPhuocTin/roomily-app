part of 'find_partner_post_detail_cubit.dart';

abstract class FindPartnerPostDetailState extends Equatable {
  const FindPartnerPostDetailState();

  @override
  List<Object?> get props => [];
}

class FindPartnerPostDetailInitial extends FindPartnerPostDetailState {}

class FindPartnerPostDetailLoading extends FindPartnerPostDetailState {}

class FindPartnerPostDetailLoaded extends FindPartnerPostDetailState {
  final FindPartnerPostDetail postDetail;

  const FindPartnerPostDetailLoaded({required this.postDetail});

  @override
  List<Object?> get props => [postDetail];
}

class FindPartnerPostDetailError extends FindPartnerPostDetailState {
  final String message;

  const FindPartnerPostDetailError({required this.message});

  @override
  List<Object?> get props => [message];
} 
import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/rental_request.dart';

abstract class FindPartnerState extends Equatable {
  const FindPartnerState();

  @override
  List<Object?> get props => [];
}

class FindPartnerInitial extends FindPartnerState {
  const FindPartnerInitial();
}

class FindPartnerLoading extends FindPartnerState {
  const FindPartnerLoading();
}

class FindPartnerLoaded extends FindPartnerState {
  final List<FindPartnerPost> posts;

  const FindPartnerLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class FindPartnerError extends FindPartnerState {
  final String message;

  const FindPartnerError(this.message);

  @override
  List<Object?> get props => [message];
}

class FindPartnerSubmitting extends FindPartnerState {
  const FindPartnerSubmitting();
}

class FindPartnerSubmitted extends FindPartnerState {
  const FindPartnerSubmitted();
}

class FindPartnerChecking extends FindPartnerState {
  const FindPartnerChecking();
}

class FindPartnerUserCheckResult extends FindPartnerState {
  final bool isUserInPost;

  const FindPartnerUserCheckResult(this.isUserInPost);

  @override
  List<Object?> get props => [isUserInPost];
}

class FindPartnerActivePosts extends FindPartnerState {
  final List<FindPartnerPost> posts;

  const FindPartnerActivePosts(this.posts);

  @override
  List<Object?> get props => [posts];
}

class FindPartnerRequestSending extends FindPartnerState {
  const FindPartnerRequestSending();
}

class FindPartnerRequestSent extends FindPartnerState {
  final RentalRequest rentalRequest;
  
  const FindPartnerRequestSent(this.rentalRequest);
  
  @override
  List<Object?> get props => [rentalRequest];
}

class FindPartnerRequestAccepting extends FindPartnerState {
  const FindPartnerRequestAccepting();
}

class FindPartnerRequestAccepted extends FindPartnerState {
  const FindPartnerRequestAccepted();
  
  @override
  List<Object?> get props => [];
}

class FindPartnerRequestRejecting extends FindPartnerState {
  const FindPartnerRequestRejecting();
}

class FindPartnerRequestRejected extends FindPartnerState {
  const FindPartnerRequestRejected();
  
  @override
  List<Object?> get props => [];
}

class FindPartnerRequestCanceling extends FindPartnerState {
  const FindPartnerRequestCanceling();
}

class FindPartnerRequestCanceled extends FindPartnerState {
  const FindPartnerRequestCanceled();
  
  @override
  List<Object?> get props => [];
}

class FindPartnerUpdated extends FindPartnerState {
  final bool success;
  
  const FindPartnerUpdated({this.success = true});
  
  @override
  List<Object?> get props => [success];
}

class FindPartnerRemovingParticipant extends FindPartnerState {
  const FindPartnerRemovingParticipant();
}

class FindPartnerParticipantRemoved extends FindPartnerState {
  final String userId;
  
  const FindPartnerParticipantRemoved(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class FindPartnerExiting extends FindPartnerState {
  const FindPartnerExiting();
}

class FindPartnerExited extends FindPartnerState {
  const FindPartnerExited();
  
  @override
  List<Object?> get props => [];
}

class FindPartnerAddingParticipant extends FindPartnerState {
  const FindPartnerAddingParticipant();
}

class FindPartnerParticipantAdded extends FindPartnerState {
  final String privateId;
  
  const FindPartnerParticipantAdded(this.privateId);
  
  @override
  List<Object?> get props => [privateId];
}

class FindPartnerDeleting extends FindPartnerState {
  const FindPartnerDeleting();
}

class FindPartnerDeleted extends FindPartnerState {
  const FindPartnerDeleted();
} 
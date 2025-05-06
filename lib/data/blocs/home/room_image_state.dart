import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/models.dart';

abstract class RoomImageState extends Equatable {
  const RoomImageState();

  @override
  List<Object> get props => [];
}

class RoomImageInitial extends RoomImageState {}

class RoomImageLoading extends RoomImageState {
  final String? roomId;
  
  const RoomImageLoading({this.roomId});
  
  @override
  List<Object> get props => roomId != null ? [roomId!] : [];
}

class RoomImageLoaded extends RoomImageState {
  final List<RoomImage> images;
  final String? roomId;

  const RoomImageLoaded({required this.images, this.roomId});  

  @override
  List<Object> get props => roomId != null ? [images, roomId!] : [images];
}

class RoomImageError extends RoomImageState {
  final String message;
  final String? roomId;

  const RoomImageError({required this.message, this.roomId});

  @override
  List<Object> get props => roomId != null ? [message, roomId!] : [message];
}

class RoomImageUploading extends RoomImageState {
  final String? roomId;
  
  const RoomImageUploading({this.roomId});
  
  @override
  List<Object> get props => roomId != null ? [roomId!] : [];
}

class RoomImageUploadError extends RoomImageState {
  final String message;
  final String? roomId;

  const RoomImageUploadError({required this.message, this.roomId});

  @override
  List<Object> get props => roomId != null ? [message, roomId!] : [message];
}

class RoomImageDeleting extends RoomImageState {
  final String? roomId;
  
  const RoomImageDeleting({this.roomId});
  
  @override
  List<Object> get props => roomId != null ? [roomId!] : [];
}

class RoomImageDeleteSuccess extends RoomImageState {
  final String? roomId;
  
  const RoomImageDeleteSuccess({this.roomId});
  
  @override
  List<Object> get props => roomId != null ? [roomId!] : [];
}

class RoomImageDeleteError extends RoomImageState {
  final String message;
  final String? roomId;

  const RoomImageDeleteError({required this.message, this.roomId});

  @override
  List<Object> get props => roomId != null ? [message, roomId!] : [message];
}

class AllRoomImagesState extends RoomImageState {
  final Map<String, List<RoomImage>> roomImagesMap;
  final bool isLoading;
  final String? error;

  const AllRoomImagesState({
    required this.roomImagesMap,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object> get props => [roomImagesMap, isLoading, error ?? ''];

  AllRoomImagesState copyWith({
    Map<String, List<RoomImage>>? roomImagesMap,
    bool? isLoading,
    String? error,
  }) {
    return AllRoomImagesState(
      roomImagesMap: roomImagesMap ?? this.roomImagesMap,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}


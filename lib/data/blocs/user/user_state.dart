import 'package:equatable/equatable.dart';

import '../../models/user.dart';

abstract class UserInfoState extends Equatable {
  const UserInfoState();

  @override
  List<Object> get props => [];
}

class UserInfoInitial extends UserInfoState {}

class UserInfoLoading extends UserInfoState {}

class UserInfoLoaded extends UserInfoState {
  final User user;

  const UserInfoLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class UserInfoByIdLoaded extends UserInfoState {
  final User user;

  const UserInfoByIdLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class UserInfoError extends UserInfoState {
  final String message;

  const UserInfoError({required this.message});

  @override
  List<Object> get props => [message];
}

abstract class UserInfoByIdState extends Equatable {
  const UserInfoByIdState();

  @override
  List<Object> get props => [];
}


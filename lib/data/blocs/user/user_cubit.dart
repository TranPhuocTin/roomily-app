import 'package:bloc/bloc.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/blocs/user/user_state.dart';
import 'package:roomily/data/repositories/user_repository.dart';

import '../../models/user.dart';

class UserCubit extends Cubit<UserInfoState> {
  final UserRepository userRepository;

  UserCubit({required this.userRepository}) : super(UserInfoInitial());

  Future<void> getUserInfo() async {
      emit(UserInfoLoading());
      final user = await userRepository.getCurrentUserInfo();
      switch(user) {
        case Success(data: final user) :
          emit(UserInfoLoaded(user: user));
        case Failure(message: final message) :
          emit(UserInfoError(message: message));
      }
  }

  Future<void> getUserInfoById(String userId) async {
      emit(UserInfoLoading());
      final user = await userRepository.getUserInfo(userId);
      switch(user) {
        case Success(data: final user) :
          emit(UserInfoByIdLoaded(user: user));
        case Failure(message: final message) :
          emit(UserInfoError(message: message));
      }
  }

  Future<void> updateUserInfo(User userUpdate) async {
      emit(UserInfoLoading());
      try {
        await userRepository.updateUserInfo(userUpdate);
        // Sau khi cập nhật thành công, lấy thông tin người dùng mới nhất
        final userResult = await userRepository.getCurrentUserInfo();
        switch(userResult) {
          case Success(data: final user) :
            emit(UserInfoLoaded(user: user));
          case Failure(message: final message) :
            emit(UserInfoError(message: message));
        }
      } catch (e) {
        emit(UserInfoError(message: e.toString()));
      }
  }

  Future<void> updateUserAvatar(String profilePicture) async {
      emit(UserInfoLoading());
      try {
        await userRepository.updateUserAvatar(profilePicture);
        // Sau khi cập nhật avatar thành công, lấy thông tin người dùng mới nhất
        final userResult = await userRepository.getCurrentUserInfo();
        switch(userResult) {
          case Success(data: final user) :
            emit(UserInfoLoaded(user: user));
          case Failure(message: final message) :
            emit(UserInfoError(message: message));
        }
      } catch (e) {
        emit(UserInfoError(message: e.toString()));
      }
  }
}
import '../../core/utils/result.dart';
import 'package:roomily/data/models/models.dart';

abstract class UserRepository {
  Future<Result<User>> getCurrentUserInfo();
  Future<Result<User>> getUserInfo(String userId);
  Future<void> updateUserInfo(User user);
  Future<void> updateUserAvatar(String profilePicture);
  Future<void> registerFcmToken(String userId, String token);
}
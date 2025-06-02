import 'package:test1/src/domain/models/user.dart';

abstract class IUserRepository {
  Future<void> registerUser(User user);

  Future<User?> loginUser(String email, String password);

  Future<User?> getUser();

  Future<void> updateUser(User user);

  Future<void> deleteUser();
}

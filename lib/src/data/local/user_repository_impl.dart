import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/src/domain/models/user.dart';
import 'package:test1/src/domain/repositories/i_user_repository.dart';

class UserRepositoryImpl implements IUserRepository {
  final SharedPreferences _prefs;

  UserRepositoryImpl(this._prefs);

  static const String _userKey = 'user_data';

  @override
  Future<void> registerUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, userJson);
  }

  @override
  Future<User?> loginUser(String email, String password) async {
    final data = _prefs.getString(_userKey);
    if (data == null) return null;

    final map = jsonDecode(data) as Map<String, dynamic>;
    final storedUser = User.fromJson(map);

    if (storedUser.email == email && storedUser.password == password) {
      return storedUser;
    }
    return null;
  }

  @override
  Future<User?> getUser() async {
    final data = _prefs.getString(_userKey);
    if (data == null) return null;

    final map = jsonDecode(data) as Map<String, dynamic>;
    return User.fromJson(map);
  }

  @override
  Future<void> updateUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, userJson);
  }

  @override
  Future<void> deleteUser() async {
    await _prefs.remove(_userKey);
  }
}

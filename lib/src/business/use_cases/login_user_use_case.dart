import 'package:test1/src/domain/repositories/i_user_repository.dart';

class LoginUserUseCase {
  final IUserRepository repository;

  LoginUserUseCase(this.repository);

  Future<String?> execute(String email, String password) async {
    if (!email.contains('@')) {
      return 'Некоректний email';
    }
    if (password.isEmpty) {
      return 'Пароль не може бути порожнім';
    }

    final user = await repository.loginUser(email, password);
    if (user == null) {
      return 'Невірний email або пароль';
    }
    return null;
  }
}

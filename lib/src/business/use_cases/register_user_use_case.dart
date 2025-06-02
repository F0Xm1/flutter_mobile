import 'package:test1/src/domain/models/user.dart';
import 'package:test1/src/domain/repositories/i_user_repository.dart';

class RegisterUserUseCase {
  final IUserRepository repository;

  RegisterUserUseCase(this.repository);

  Future<String?> execute(User user) async {
    if (!user.email.contains('@')) {
      return 'Некоректний email';
    }
    if (user.name.isEmpty || RegExp(r'\d').hasMatch(user.name)) {
      return 'Ім’я не може містити цифри';
    }
    if (user.password.length < 6) {
      return 'Пароль має бути не менше 6 символів';
    }

    await repository.registerUser(user);
    return null;
  }
}

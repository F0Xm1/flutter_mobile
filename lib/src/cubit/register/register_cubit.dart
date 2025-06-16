import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/business/use_cases/register_user_use_case.dart';
import 'package:test1/src/domain/models/user.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterUserUseCase _registerUserUseCase;

  RegisterCubit({
    required RegisterUserUseCase registerUserUseCase,
  })  : _registerUserUseCase = registerUserUseCase,
        super(RegisterInitial());

  Future<void> register({
    required String email,
    required String name,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      emit(RegisterFailure('Паролі не співпадають'));
      return;
    }

    emit(RegisterLoading());

    final user = User(email: email, name: name, password: password);
    final error = await _registerUserUseCase.execute(user);

    if (error != null) {
      emit(RegisterFailure(error));
    } else {
      emit(RegisterSuccess());
    }
  }
}

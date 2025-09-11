import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/src/business/use_cases/login_user_use_case.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUserUseCase _loginUserUseCase;
  final SharedPreferences _prefs;

  AuthCubit({
    required LoginUserUseCase loginUserUseCase,
    required SharedPreferences prefs,
  })  : _loginUserUseCase = loginUserUseCase,
        _prefs = prefs,
        super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final error = await _loginUserUseCase.execute(username, password);
      if (error == null) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(error));
      }
    } catch (e) {
      emit(AuthFailure('Сталася помилка: $e'));
    }
  }

  Future<void> checkAutoLogin() async {
    final isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      emit(AuthSuccess());
    } else {
      emit(AuthInitial());
    }
  }

  void logout() {
    _prefs.setBool('isLoggedIn', false);
    emit(AuthInitial());
  }
}

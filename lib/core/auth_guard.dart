import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/data/repositories/location_repository.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/screens/auth_page/login_page.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkLocations());
    }
  }

  Future<void> _checkLocations() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final locations = await LocationRepository().getLocations();
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        locations.isEmpty ? '/onboarding' : '/home',
      );
    } catch (_) {
      if (!mounted) return;
      await Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _checkLocations();
        }
      },
      builder: (context, state) {
        if (state is AuthLoading ||
            state is AuthInitial ||
            state is AuthAuthenticated) {
          return const Scaffold(
            backgroundColor: AppColors.bgDeep,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          );
        }
        return const LoginPage();
      },
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/core/auth_guard.dart';
import 'package:test1/firebase_options.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_event.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/screens/auth_page/login_page.dart';
import 'package:test1/src/screens/auth_page/register_page.dart';
import 'package:test1/src/screens/events_page/events_page.dart';
import 'package:test1/src/screens/home_page/home_page.dart';
import 'package:test1/src/screens/onboarding_page/onboarding_page.dart';
import 'package:test1/src/screens/profile_page/profile_page.dart';
import 'package:test1/src/screens/sensors_page/sensors_page.dart';
import 'package:test1/src/screens/telemetry/telemetry_page.dart';
import 'package:test1/src/services/push_mess/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);

  const supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKeyFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  final supabaseUrl = supabaseUrlFromDefine.isNotEmpty
      ? supabaseUrlFromDefine
      : dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = supabaseAnonKeyFromDefine.isNotEmpty
      ? supabaseAnonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL або SUPABASE_ANON_KEY не знайдено в .env чи dart-define',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FCMService.init();
  } catch (_) {
    // FCM unavailable on this device — app continues without push notifications
  }

  final connectivity = Connectivity();

  runApp(
    MultiProvider(
      providers: [
        Provider<Connectivity>.value(value: connectivity),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionBloc>(
            create: (context) => ConnectionBloc(
              context.read<Connectivity>(),
            )..add(ConnectionStarted()),
          ),
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Чіпідізєль',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          surface: AppColors.bgSurface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgElevated,
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white30),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.orange,
              width: 2,
            ),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthGuard());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/telemetry':
            final args = settings.arguments;
            String? locationId;
            String locationName = '';
            if (args is Map) {
              locationId = args['locationId'] as String?;
              locationName = args['locationName'] as String? ?? '';
            } else if (args is String?) {
              locationId = args;
            }
            return MaterialPageRoute(
              builder: (_) => TelemetryPage(
                locationId: locationId,
                locationName: locationName,
              ),
            );
          case '/events':
            return MaterialPageRoute(builder: (_) => const EventsPage());
          case '/sensors':
            return MaterialPageRoute(builder: (_) => const SensorsPage());
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingPage(),
            );
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 — Маршрут не знайдено')),
              ),
            );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'features/sms/presentation/sms_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/sync/api_service.dart';
import 'features/sms/data/sms_service.dart';
import 'features/sms/data/sms_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KashioApp());
}

class KashioApp extends StatelessWidget {
  const KashioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final apiService = ApiService(authService: authService);
    final smsService = SmsService();
    final smsRepository = SmsRepository(smsService: smsService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: authService)),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            smsRepository: smsRepository,
            apiService: apiService,
            authService: authService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Kashio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            return const SmsScreen();
          case AuthStatus.unauthenticated:
            return const AuthScreen();
        }
      },
    );
  }
}
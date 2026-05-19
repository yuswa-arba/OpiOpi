import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_theme.dart';
import 'screens/book_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_selection_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const OpiOpiApp());
}

class OpiOpiApp extends StatelessWidget {
  const OpiOpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpiOpi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  Future<List<String?>> _loadSession() => Future.wait([
        StorageService.getActiveUser(),
        StorageService.getActiveBookId(),
        StorageService.getActiveBookName(),
      ]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String?>>(
      future: _loadSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashView();
        }
        final data = snapshot.data!;
        final user = data[0];
        final bookId = data[1];
        final bookName = data[2];

        if (user == null || user.isEmpty) {
          return const UserSelectionScreen();
        }
        if (bookId == null || bookId.isEmpty) {
          return BookSelectionScreen(activeUser: user, onboarding: true);
        }
        return HomeScreen(activeUser: user, activeBookName: bookName ?? '');
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary, Color(0xFFFFD6E3), AppTheme.background],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon-remove-background.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'OpiOpi',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keuangan Keluarga',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

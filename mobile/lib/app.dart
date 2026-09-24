import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/networking/api_client.dart';
import 'core/theme/nova_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/shell/screens/main_shell.dart';

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});

  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  final api = ApiClient();
  bool? authenticated;
  bool? onboardingSeen;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('nova_onboarding_seen') ?? false;
    final theme = prefs.getString('nova_theme') ?? 'dark';
    final restored = await api.restoreSession();
    if (!mounted) return;
    setState(() {
      onboardingSeen = seen;
      _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
      authenticated = restored;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nova_onboarding_seen', true);
    if (mounted) setState(() => onboardingSeen = true);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nova_theme', mode == ThemeMode.light ? 'light' : 'dark');
    if (mounted) setState(() => _themeMode = mode);
  }

  void _authenticated() => setState(() => authenticated = true);
  void _loggedOut() => setState(() => authenticated = false);

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (authenticated == null || onboardingSeen == null) {
      home = const _StartupScreen();
    } else if (onboardingSeen == false) {
      home = OnboardingScreen(onDone: _finishOnboarding);
    } else if (authenticated == true) {
      home = MainShell(
        api: api,
        onLogout: _loggedOut,
        themeMode: _themeMode,
        onThemeChanged: _setTheme,
      );
    } else {
      home = AuthScreen(api: api, onAuthenticated: _authenticated);
    }

    return MaterialApp(
      title: 'NOVA',
      debugShowCheckedModeBanner: false,
      theme: NovaTheme.light,
      darkTheme: NovaTheme.dark,
      themeMode: _themeMode,
      home: home,
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B6CFF), Color(0xFF5D3FE8)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(child: Text('N', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white))),
              ),
              const SizedBox(height: 20),
              const Text('NOVA', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6)),
              const SizedBox(height: 22),
              const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/root_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LivApp());
}

class LivApp extends StatelessWidget {
  const LivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          ThemeMode mode;
          switch (state.profile.themeMode) {
            case 'light':
              mode = ThemeMode.light;
              break;
            case 'dark':
              mode = ThemeMode.dark;
              break;
            default:
              mode = ThemeMode.system;
          }
          final danger = state.profile.hearts <= 0;
          final accent = state.profile.accentColor;
          final isRtl = state.profile.locale != 'en';

          return MaterialApp(
            title: 'Liv',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(accent: accent, danger: danger),
            darkTheme: AppTheme.dark(accent: accent, danger: danger),
            themeMode: mode,
            builder: (context, child) => Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: state.profile.hearts <= 0
                    ? AppColors.danger
                    : AppColors.accentFrom(state.profile.accentColor),
              ),
              const SizedBox(height: 16),
              Text(state.profile.locale == 'en' ? 'Liv is opening...' : 'Liv بيفتح ليك...'),
            ],
          ),
        ),
      );
    }
    if (!state.profile.hasOnboarded) {
      return const OnboardingScreen();
    }
    return const RootShell();
  }
}

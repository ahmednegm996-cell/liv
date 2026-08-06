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

          final isRtl = state.profile.locale != 'en';

          return MaterialApp(
            title: 'Liv',
            debugShowCheckedModeBanner: false,
            theme: buildLivTheme(Brightness.light, state.profile.accentColor),
            darkTheme: buildLivTheme(Brightness.dark, state.profile.accentColor),
            themeMode: mode,
            locale: Locale(state.profile.locale == 'en' ? 'en' : 'ar'),
            builder: (context, child) {
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: state.loading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : (state.profile.hasOnboarded
                    ? const RootShell()
                    : const OnboardingScreen()),
          );
        },
      ),
    );
  }
}

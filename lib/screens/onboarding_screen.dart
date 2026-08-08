import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// FULL CONTENT TOO LARGE FOR THIS DEMO - use push_files with proper content
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

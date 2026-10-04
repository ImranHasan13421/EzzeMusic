import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ezze.ezzemusic.channel.audio',
      androidNotificationChannelName: 'EzzeMusic Playback',
      androidNotificationOngoing: true,
    );
  }

  // Initialize AppState and wait for settings (Accent color, playlists, etc.) to load
  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const EzzeMusic(),
    ),
  );
}

class EzzeMusic extends StatelessWidget {
  const EzzeMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final accent = app.accentColor;
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isDark = switch (app.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system => platformBrightness == Brightness.dark,
        };
        AppColors.current =
            isDark ? AppColors.darkPalette : AppColors.lightPalette;

        return MaterialApp(
          title: 'EzzeMusic',
          debugShowCheckedModeBanner: false,
          themeMode: app.themeMode,
          theme: AppTheme.light(accent),
          darkTheme: AppTheme.dark(accent),
          home: const SplashScreen(),
        );
      },
    );
  }
}
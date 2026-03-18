import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/magical_sky_background.dart';

class DrawForFunApp extends StatelessWidget {
  const DrawForFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw For Fun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // MagicalSkyBackground wraps every route — all screens get the
      // gradient + sparkles with no per-screen changes required.
      builder: (context, child) => MagicalSkyBackground(child: child!),
      home: const MainMenuScreen(),
    );
  }
}

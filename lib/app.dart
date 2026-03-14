import 'package:flutter/material.dart';
import 'screens/coloring_screen.dart';

class DrawForFunApp extends StatelessWidget {
  const DrawForFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw For Fun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ColoringScreen(),
    );
  }
}

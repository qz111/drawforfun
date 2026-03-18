import 'package:flutter/material.dart';

class AirbrushTheme {
  final Color baseColor;
  final List<String> emojis;
  final String label;
  const AirbrushTheme({
    required this.baseColor,
    required this.emojis,
    required this.label,
  });
}

class PatternStyle {
  final List<String> emojis;
  final Color backgroundColor;
  final String label;
  const PatternStyle({
    required this.emojis,
    required this.backgroundColor,
    required this.label,
  });
}

class BrushTheme {
  BrushTheme._();

  static const List<AirbrushTheme> airbrushThemes = [
    AirbrushTheme(baseColor: Color(0xFF1565C0), emojis: ['🌸', '🌼', '✨'], label: 'Blue + Gold Flowers'),
    AirbrushTheme(baseColor: Color(0xFFF9A825), emojis: ['🌈', '☁️', '🌟'], label: 'Yellow + Rainbows'),
    AirbrushTheme(baseColor: Color(0xFF880E4F), emojis: ['🦋', '💜', '🌸'], label: 'Pink + Butterflies'),
    AirbrushTheme(baseColor: Color(0xFF1B5E20), emojis: ['✨', '⭐', '🌟'], label: 'Green + Stars'),
    AirbrushTheme(baseColor: Color(0xFFB71C1C), emojis: ['🔥', '💥', '⚡'], label: 'Red + Fire'),
    AirbrushTheme(baseColor: Color(0xFF006064), emojis: ['🌊', '🐟', '💧'], label: 'Teal + Ocean'),
    AirbrushTheme(baseColor: Color(0xFF4A148C), emojis: ['🪄', '🌙', '💫'], label: 'Purple + Magic'),
    AirbrushTheme(baseColor: Color(0xFFE65100), emojis: ['🍂', '🍁', '🎃'], label: 'Orange + Autumn'),
    AirbrushTheme(baseColor: Color(0xFF37474F), emojis: ['🌙', '⭐', '🛸'], label: 'Dark + Space'),
    AirbrushTheme(baseColor: Color(0xFFF48FB1), emojis: ['🍭', '🍬', '🎀'], label: 'Pink + Candy'),
  ];

  static const List<PatternStyle> patternStyles = [
    PatternStyle(emojis: ['⭐', '🌟', '✨'], backgroundColor: Color(0xFFFFF9C4), label: 'Stars'),
    PatternStyle(emojis: ['🌙'],             backgroundColor: Color(0xFFE3F2FD), label: 'Moons'),
    PatternStyle(emojis: ['☀️', '🌤️'],      backgroundColor: Color(0xFFFFFDE7), label: 'Suns'),
    PatternStyle(emojis: ['🌸', '🌺'],       backgroundColor: Color(0xFFF3E5F5), label: 'Flowers'),
    PatternStyle(emojis: ['🦋', '🌿'],       backgroundColor: Color(0xFFE8F5E9), label: 'Butterflies'),
    PatternStyle(emojis: ['❤️', '💙', '💚'], backgroundColor: Color(0xFFFCE4EC), label: 'Hearts'),
    PatternStyle(emojis: ['🐠', '🐡', '🐟'], backgroundColor: Color(0xFFE0F2F1), label: 'Fish'),
    PatternStyle(emojis: ['🎈', '🎀', '🎊'], backgroundColor: Color(0xFFFFF3E0), label: 'Party'),
    PatternStyle(emojis: ['❄️', '⛄', '🌨️'], backgroundColor: Color(0xFFFAFAFA), label: 'Snow'),
    PatternStyle(emojis: ['🍦', '🍰', '🧁'], backgroundColor: Color(0xFFFCE4EC), label: 'Sweets'),
  ];
}

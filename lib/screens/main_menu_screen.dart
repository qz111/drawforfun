import 'package:flutter/material.dart';
import 'template_lib_screen.dart';
import 'my_upload_lib_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎨 Draw For Fun',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4C1D95),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _MenuCard(
                      emoji: '🐾',
                      label: 'Templates',
                      subtitle: 'Built-in animals & your raw photos',
                      borderColor: const Color(0xFF7C3AED),
                      labelColor: const Color(0xFF4C1D95),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const TemplateLibScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _MenuCard(
                      emoji: '📷',
                      label: 'My Uploads',
                      subtitle: 'Edge-detected line art drawings',
                      borderColor: const Color(0xFF059669),
                      labelColor: const Color(0xFF065F46),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const MyUploadLibScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.borderColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

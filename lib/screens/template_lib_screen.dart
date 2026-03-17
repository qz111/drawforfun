import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../templates/animal_templates.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';
import 'contour_creator_screen.dart';

class TemplateLibScreen extends StatefulWidget {
  const TemplateLibScreen({super.key});

  @override
  State<TemplateLibScreen> createState() => _TemplateLibScreenState();
}

class _TemplateLibScreenState extends State<TemplateLibScreen> {
  bool _isLoading = true;
  bool _isImporting = false;
  List<_CardData> _cards = [];
  List<_CardData> _customCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final results = await Future.wait<List<_CardData>>([
      Future.wait(
        AnimalTemplates.all.map((template) async {
          final entry = await DrawingRepository.templateEntry(template);
          return _CardData(
            entry: entry,
            label: template.name,
            emoji: template.emoji,
            hasThumbnail: File(entry.thumbnailPath).existsSync(),
          );
        }),
      ),
      DrawingRepository.listRawImportEntries().then((entries) => entries
          .map((entry) => _CardData(
                entry: entry,
                label: _uploadLabel(entry.id),
                emoji: '📷',
                hasThumbnail: File(entry.thumbnailPath).existsSync(),
              ))
          .toList()),
      DrawingRepository.listCustomTemplateEntries().then((entries) => entries
          .map((entry) => _CardData(
                entry: entry,
                label: _customLabel(entry.id),
                emoji: '🎨',
                hasThumbnail: File(entry.thumbnailPath).existsSync(),
              ))
          .toList()),
    ]);
    if (mounted) {
      setState(() {
        _cards = [...results[0], ...results[1]];
        _customCards = results[2];
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    await FileImage(File(entry.thumbnailPath)).evict();
    _loadData();
  }

  Future<void> _openRemix(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ContourCreatorScreen(
          remixSourcePath: entry.overlayFilePath,
          remixAssetPath: entry.overlayAssetPath,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _startRawImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;
    setState(() => _isImporting = true);
    try {
      await DrawingRepository.createRawImportEntry(result.files.single.bytes!);
      _loadData();
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmDelete(_CardData card) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        entry: card.entry,
        onConfirmed: () {
          _loadData();
        },
      ),
    );
  }

  String _uploadLabel(String id) {
    try {
      final date = id.split('_')[1];
      return 'Photo ${date.substring(4, 6)}/${date.substring(6, 8)}';
    } catch (_) {
      return 'Photo';
    }
  }

  String _customLabel(String id) {
    try {
      final date = id.split('_')[1];
      return 'Template ${date.substring(4, 6)}/${date.substring(6, 8)}';
    } catch (_) {
      return 'Template';
    }
  }

  void _showRemixSheet(_CardData card) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What would you like to do?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetOption(
                      label: 'Color it!',
                      icon: Icons.brush,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _openEntry(card.entry);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetOption(
                      label: 'Remix it',
                      icon: Icons.edit,
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.pop(context);
                        _openRemix(card.entry);
                      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          '🐾 Templates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: const Text('+ Upload'),
                onPressed: _startRawImport,
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap a drawing to start coloring',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  // ── Main carousel (built-ins + raw imports) ───────────────
                  SizedBox(
                    height: 200,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Create Blank Canvas — static first card
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 200,
                              child: _CreateBlankCard(
                                onTap: () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ContourCreatorScreen(),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            ),
                          ),
                          // Built-in + rawImport cards
                          ..._cards.map((card) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 200,
                                  child: DrawingCardWidget(
                                    entry: card.entry,
                                    label: card.label,
                                    emoji: card.emoji,
                                    hasThumbnail: card.hasThumbnail,
                                    onTap: () => _openEntry(card.entry),
                                    onLongPress: () => _showRemixSheet(card),
                                    onDelete: card.entry.type ==
                                            DrawingType.template
                                        ? null
                                        : () => _confirmDelete(card),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  // ── My Templates section (only when non-empty) ────────────
                  if (_customCards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'My Templates',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _customCards.map((card) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 200,
                                child: DrawingCardWidget(
                                  entry: card.entry,
                                  label: card.label,
                                  emoji: card.emoji,
                                  hasThumbnail: card.hasThumbnail,
                                  onTap: () => _openEntry(card.entry),
                                  onLongPress: () => _showRemixSheet(card),
                                  onDelete: () => _confirmDelete(card),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CardData {
  final DrawingEntry entry;
  final String label;
  final String? emoji;
  final bool hasThumbnail;
  _CardData({
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
  });
}

// ── DeleteConfirmationDialog ─────────────────────────────────────────────────
// Handles cache eviction and file deletion internally.
// onConfirmed only updates the caller's UI list.

/// A dialog that requires the user to solve a simple addition problem
/// before permanently deleting a user-owned drawing entry.
///
/// The math gate (sum of two random numbers 5–15) is trivially easy for
/// adults but reliably unsolvable by children aged 3–5.
class DeleteConfirmationDialog extends StatefulWidget {
  final DrawingEntry entry;
  final VoidCallback onConfirmed;

  const DeleteConfirmationDialog({
    super.key,
    required this.entry,
    required this.onConfirmed,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  late final int _a;
  late final int _b;
  late final int _answer;
  final _controller = TextEditingController();
  String? _errorText;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 5 + rng.nextInt(11);
    _b = 5 + rng.nextInt(11);
    _answer = _a + _b;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final input = int.tryParse(_controller.text.trim());
    if (input != _answer) {
      setState(() {
        _errorText = 'Wrong answer, try again';
        _controller.clear();
      });
      return;
    }
    setState(() => _isDeleting = true);
    try {
      final overlayFile = widget.entry.overlayFilePath;
      if (overlayFile != null) {
        imageCache.evict(FileImage(File(overlayFile)));
      }
      imageCache.evict(FileImage(File(widget.entry.thumbnailPath)));
      await DrawingRepository.deleteEntry(widget.entry);
      widget.onConfirmed();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete this image?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What is $_a + $_b?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Your answer',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _onDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ── _SheetOption ─────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _CreateBlankCard ──────────────────────────────────────────────────────────

class _CreateBlankCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateBlankCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.deepPurple.shade300,
            width: 2.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 40, color: Colors.deepPurple.shade400),
            const SizedBox(height: 10),
            Text(
              'Create Blank Canvas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

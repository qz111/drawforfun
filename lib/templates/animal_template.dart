/// Immutable descriptor for a built-in animal line-art template.
class AnimalTemplate {
  final String id;         // file stem, e.g. 'cat'
  final String name;       // display name, e.g. 'Cat'
  final String emoji;      // decorative emoji, e.g. '🐱'
  final String assetPath;  // Flutter asset path, e.g. 'assets/line_art/cat.svg'

  const AnimalTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.assetPath,
  });

  @override
  bool operator ==(Object other) =>
      other is AnimalTemplate &&
      other.id == id &&
      other.name == name &&
      other.emoji == emoji &&
      other.assetPath == assetPath;

  @override
  int get hashCode => Object.hash(id, name, emoji, assetPath);
}

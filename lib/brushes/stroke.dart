import 'package:flutter/material.dart';
import 'brush_type.dart';

/// Immutable record of one continuous touch gesture.
class Stroke {
  final BrushType type;
  final Color color;
  final List<Offset> points;

  /// Theme index (0–9) for airbrush and pattern brushes.
  /// For eraser strokes, encodes size: 0 = Small, 1 = Medium, 2 = Large.
  /// Null for other color-based brushes (pencil, marker, splatter).
  /// When non-null, BrushEngine ignores [color] and uses the index instead.
  final int? themeIndex;

  const Stroke({
    required this.type,
    required this.color,
    required this.points,
    this.themeIndex,
  });

  /// Returns a new Stroke with [point] appended to the points list.
  Stroke copyWithPoint(Offset point) {
    return Stroke(
      type: type,
      color: color,
      points: [...points, point],
      themeIndex: themeIndex,
    );
  }

  /// Serializes this stroke to a JSON-compatible map.
  /// JSON key 'brushType' maps to the Dart field [type].
  Map<String, dynamic> toJson() => {
        'brushType': type.name,
        'color': color.toARGB32(),
        'points': points
            .map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
        'themeIndex': themeIndex,
      };

  /// Restores a [Stroke] from the map produced by [toJson].
  /// Returns null-safe: unknown brushType names throw [ArgumentError] via [byName].
  static Stroke fromJson(Map<String, dynamic> json) => Stroke(
        type: BrushType.values.byName(json['brushType'] as String),
        color: Color(json['color'] as int),
        points: (json['points'] as List)
            .map((p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ))
            .toList(),
        themeIndex: json['themeIndex'] as int?,
      );
}

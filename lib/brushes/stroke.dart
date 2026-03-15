import 'package:flutter/material.dart';
import 'brush_type.dart';

/// Immutable record of one continuous touch gesture.
class Stroke {
  final BrushType type;
  final Color color;
  final List<Offset> points;

  const Stroke({
    required this.type,
    required this.color,
    required this.points,
  });

  /// Returns a new Stroke with [point] appended to the points list.
  Stroke copyWithPoint(Offset point) {
    return Stroke(
      type: type,
      color: color,
      points: [...points, point],
    );
  }

  /// Serializes this stroke to a JSON-compatible map.
  /// JSON key 'brushType' maps to the Dart field [type].
  Map<String, dynamic> toJson() => {
        'brushType': type.name,
        'color': color.value,
        'points': points
            .map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
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
      );
}

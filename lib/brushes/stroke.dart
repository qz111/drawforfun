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
}

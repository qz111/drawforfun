import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'app.dart';

void main() {
  // Register fvp as the video_player backend for platforms not covered by the
  // default plugin (Windows, Linux, macOS). No-op on Android/iOS/Web.
  fvp.registerWith();
  runApp(const DrawForFunApp());
}

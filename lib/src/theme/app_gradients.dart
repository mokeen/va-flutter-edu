import 'package:flutter/material.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient aquaDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF020617),
      Color(0xFF000000),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient aquaLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
      Color(0xFFCBD5E1),
    ],
    stops: [0.0, 0.6, 1.0],
  );
}


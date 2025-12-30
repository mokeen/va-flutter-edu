import 'package:flutter/material.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient aquaDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 1, 10, 49),
      Color.fromARGB(255, 5, 3, 28),
      Color.fromARGB(255, 14, 10, 25),
    ],
    stops: [0.0, 0.55, 1.0],
  );
}


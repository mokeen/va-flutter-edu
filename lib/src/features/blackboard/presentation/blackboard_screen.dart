import 'package:flutter/material.dart';

class BlackboardScreen extends StatelessWidget {
  const BlackboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color.fromARGB(6, 2, 27, 165))
        ),
      )
    );
  }
}

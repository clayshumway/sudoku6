import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class WinAnimation extends StatelessWidget {
  final ConfettiController controller;

  const WinAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirection: -3.14159 / 2,
      numberOfParticles: 24,
      maxBlastForce: 20,
      minBlastForce: 8,
      emissionFrequency: 0.05,
      gravity: 0.3,
    );
  }
}

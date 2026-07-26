import 'package:flutter/material.dart';

/// Constrains page content to a phone-shaped column on wide viewports.
///
/// The app is designed phone-first; on a desktop browser an unconstrained
/// body stretches list tiles and buttons across the full window, which reads
/// as broken rather than spacious. Top-aligned (not centered) so scrolling
/// pages keep their natural anchor.
class PageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageBody({super.key, required this.child, this.maxWidth = 560});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

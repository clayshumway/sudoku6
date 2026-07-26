import 'package:flutter/material.dart';

import '../../../../utils/difficulty_label.dart';

class TimerWidget extends StatelessWidget {
  final int seconds;

  const TimerWidget({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 18),
        const SizedBox(width: 4),
        Text(formatMinutesSeconds(seconds)),
      ],
    );
  }
}

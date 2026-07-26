import '../engine/models/difficulty.dart';

String difficultyLabel(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return 'Easy';
    case Difficulty.medium:
      return 'Medium';
    case Difficulty.hard:
      return 'Hard';
    case Difficulty.expert:
      return 'Expert';
    case Difficulty.master:
      return 'Master';
  }
}

String formatMinutesSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

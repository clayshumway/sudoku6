import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/local_puzzle_repository.dart';
import '../data/repositories/local_settings_repository.dart';
import '../data/repositories/local_stats_repository.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/stats_repository.dart';

/// The only place that knows which concrete (local vs. future cloud-backed)
/// repository implementation is in use.
final puzzleRepositoryProvider =
    Provider<PuzzleRepository>((ref) => LocalPuzzleRepository());

final statsRepositoryProvider =
    Provider<StatsRepository>((ref) => LocalStatsRepository());

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => LocalSettingsRepository());

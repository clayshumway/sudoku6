import 'package:hive_flutter/hive_flutter.dart';

import 'models/puzzle_state_hive.dart';
import 'models/settings_hive.dart';
import 'models/stats_entry_hive.dart';

class HiveBoxes {
  static const puzzleStates = 'puzzle_states';
  static const stats = 'stats';
  static const settings = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PuzzleStateHiveAdapter());
    Hive.registerAdapter(StatsEntryHiveAdapter());
    Hive.registerAdapter(SettingsHiveAdapter());
    await Hive.openBox<PuzzleStateHive>(puzzleStates);
    await Hive.openBox<StatsEntryHive>(stats);
    await Hive.openBox<SettingsHive>(settings);
  }
}

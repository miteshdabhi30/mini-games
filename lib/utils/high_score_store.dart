import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighScoreStore {
  HighScoreStore._();

  static const String _boxName = 'high_scores';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<int>(_boxName);
    await _migrateFromSharedPreferences();
    _initialized = true;
  }

  static Box<int> get _box => Hive.box<int>(_boxName);

  static int getHighScore(String key) {
    return _box.get(key, defaultValue: 0) ?? 0;
  }

  static Future<void> setHighScore(String key, int score) async {
    await _box.put(key, score);
  }

  static Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    const legacyKeys = [
      'highScore',
      'snake_highScore',
      'colorMatch_highScore',
      'towerStack_highScore',
    ];

    for (final key in legacyKeys) {
      if (_box.containsKey(key)) continue;
      final value = prefs.getInt(key);
      if (value != null) {
        await _box.put(key, value);
      }
    }
  }
}

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final DatabaseHelper _databaseHelper;

  SettingsRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  AppSettings _fromMap(Map<String, Object?> map) {
    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (language) => language.name == map['language'],
      ),
    );
  }

  Map<String, Object?> _toMap(AppSettings settings) {
    return {'id': 1, 'language': settings.language.name};
  }

  // Get current app settings.
  Future<AppSettings> getSettings() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      const defaultSettings = AppSettings(language: AppLanguage.vi);

      await db.insert(
        'app_settings',
        _toMap(defaultSettings),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return defaultSettings;
    }

    return _fromMap(result.first);
  }

  // Get current app language.
  Future<AppLanguage> getLanguage() async {
    final settings = await getSettings();
    return settings.language;
  }

  // Update app language.
  Future<int> updateLanguage(AppLanguage language) async {
    final db = await _databaseHelper.database;

    return db.update(
      'app_settings',
      {'language': language.name},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Update all app settings.
  Future<int> updateSettings(AppSettings settings) async {
    final db = await _databaseHelper.database;

    return db.update(
      'app_settings',
      _toMap(settings),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}

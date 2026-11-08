import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/reminder.dart';

class ReminderRepository {
  final DatabaseHelper _databaseHelper;

  ReminderRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Reminder _fromMap(Map<String, Object?> map) {
    return Reminder(
      id: map['id'] as String,
      assignmentId: map['assignment_id'] as String,
      reminderType: ReminderType.values.firstWhere(
        (type) => type.name == map['reminder_type'],
      ),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      notificationId: map['notification_id'] as int,
      isScheduled: (map['is_scheduled'] as int) == 1,
    );
  }

  Map<String, Object?> _toMap(Reminder reminder) {
    return {
      'id': reminder.id,
      'assignment_id': reminder.assignmentId,
      'reminder_type': reminder.reminderType.name,
      'scheduled_at': reminder.scheduledAt.toIso8601String(),
      'notification_id': reminder.notificationId,
      'is_scheduled': reminder.isScheduled ? 1 : 0,
    };
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await _databaseHelper.database;

    final result = await db.query('reminders', orderBy: 'scheduled_at ASC');

    return result.map(_fromMap).toList();
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  Future<Reminder?> getReminderByNotificationId(int notificationId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'reminders',
      where: 'notification_id = ?',
      whereArgs: [notificationId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  Future<List<Reminder>> getRemindersByAssignment(String assignmentId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'reminders',
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
      orderBy: 'scheduled_at ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<List<Reminder>> getPendingReminders() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'reminders',
      where: 'is_scheduled = ?',
      whereArgs: [0],
      orderBy: 'scheduled_at ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<List<Reminder>> getScheduledReminders() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'reminders',
      where: 'is_scheduled = ?',
      whereArgs: [1],
      orderBy: 'scheduled_at ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<int> insertReminder(Reminder reminder) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'reminders',
      _toMap(reminder),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await _databaseHelper.database;

    return db.update(
      'reminders',
      _toMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> updateReminderScheduleStatus(String id, bool isScheduled) async {
    final db = await _databaseHelper.database;

    return db.update(
      'reminders',
      {'is_scheduled': isScheduled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminder(String id) async {
    final db = await _databaseHelper.database;

    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRemindersByAssignment(String assignmentId) async {
    final db = await _databaseHelper.database;

    return db.delete(
      'reminders',
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
    );
  }

  Future<int> getReminderCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM reminders');

    return Sqflite.firstIntValue(result) ?? 0;
  }
}

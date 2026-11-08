import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final DatabaseHelper _databaseHelper;

  ScheduleRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  TimeOfDay _minutesToTime(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Schedule _fromMap(Map<String, Object?> map) {
    return Schedule(
      id: map['id'] as String,
      subjectCode: map['subject_code'] as String,
      weekday: map['weekday'] as int,
      startTime: _minutesToTime(map['start_time'] as int),
      endTime: _minutesToTime(map['end_time'] as int),
      location: map['location'] as String?,
    );
  }

  Map<String, Object?> _toMap(Schedule schedule) {
    return {
      'id': schedule.id,
      'subject_code': schedule.subjectCode,
      'weekday': schedule.weekday,
      'start_time': _timeToMinutes(schedule.startTime),
      'end_time': _timeToMinutes(schedule.endTime),
      'location': schedule.location,
    };
  }

  Future<List<Schedule>> getAllSchedules() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'schedules',
      orderBy: 'weekday ASC, start_time ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<Schedule?> getScheduleById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  Future<List<Schedule>> getSchedulesBySubject(String subjectCode) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'schedules',
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
      orderBy: 'weekday ASC, start_time ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<List<Schedule>> getSchedulesByWeekday(int weekday) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'schedules',
      where: 'weekday = ?',
      whereArgs: [weekday],
      orderBy: 'start_time ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<List<Schedule>> getSchedulesForDate(DateTime date) {
    return getSchedulesByWeekday(date.weekday);
  }

  Future<int> insertSchedule(Schedule schedule) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'schedules',
      _toMap(schedule),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await _databaseHelper.database;

    return db.update(
      'schedules',
      _toMap(schedule),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(String id) async {
    final db = await _databaseHelper.database;

    return db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getScheduleCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM schedules');

    return Sqflite.firstIntValue(result) ?? 0;
  }
}

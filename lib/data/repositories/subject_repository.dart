import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/subject.dart';

class SubjectRepository {
  final DatabaseHelper _databaseHelper;

  SubjectRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Convert database data to Subject model.
  Subject _fromMap(Map<String, Object?> map) {
    return Subject(
      subjectCode: map['subject_code'] as String,
      name: map['name'] as String,
      lecturer: map['lecturer'] as String?,
      description: map['description'] as String?,
      color: map['color'] as String,
    );
  }

  // Convert Subject model to database data.
  Map<String, Object?> _toMap(Subject subject) {
    return {
      'subject_code': subject.subjectCode,
      'name': subject.name,
      'lecturer': subject.lecturer,
      'description': subject.description,
      'color': subject.color,
    };
  }

  // Get all subjects.
  Future<List<Subject>> getAllSubjects() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'subjects',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Get subject by code.
  Future<Subject?> getSubjectByCode(String subjectCode) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'subjects',
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  // Search subjects by name or code.
  Future<List<Subject>> searchSubjects(String keyword) async {
    final db = await _databaseHelper.database;
    final normalizedKeyword = keyword.trim();

    if (normalizedKeyword.isEmpty) {
      return getAllSubjects();
    }

    final result = await db.query(
      'subjects',
      where: '''
        name LIKE ? COLLATE NOCASE
        OR subject_code LIKE ? COLLATE NOCASE
      ''',
      whereArgs: ['%$normalizedKeyword%', '%$normalizedKeyword%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Insert a new subject.
  Future<int> insertSubject(Subject subject) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'subjects',
      _toMap(subject),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Update an existing subject.
  Future<int> updateSubject(Subject subject) async {
    final db = await _databaseHelper.database;

    return db.update(
      'subjects',
      _toMap(subject),
      where: 'subject_code = ?',
      whereArgs: [subject.subjectCode],
    );
  }

  // Delete a subject.
  // SQLite RESTRICT prevents deletion if assignments or schedules
  // are still linked to this subject.
  Future<int> deleteSubject(String subjectCode) async {
    final db = await _databaseHelper.database;

    return db.delete(
      'subjects',
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
    );
  }
}

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/assignment.dart';

class AssignmentRepository {
  final DatabaseHelper _databaseHelper;

  AssignmentRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Convert database data to Assignment model.
  Assignment _fromMap(Map<String, Object?> map) {
    return Assignment(
      id: map['id'] as String,
      title: map['title'] as String,
      subjectCode: map['subject_code'] as String,
      assignedDate: DateTime.parse(map['assigned_date'] as String),
      deadline: DateTime.parse(map['deadline'] as String),
      description: map['description'] as String?,
      note: map['note'] as String?,
      status: AssignmentStatus.values.firstWhere(
        (status) => status.name == map['status'],
      ),
    );
  }

  // Convert Assignment model to database data.
  Map<String, Object?> _toMap(Assignment assignment) {
    return {
      'id': assignment.id,
      'title': assignment.title,
      'subject_code': assignment.subjectCode,
      'assigned_date': _formatDate(assignment.assignedDate),
      'deadline': assignment.deadline.toIso8601String(),
      'description': assignment.description,
      'note': assignment.note,
      'status': assignment.status.name,
    };
  }

  // Store assigned date as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Get all assignments.
  Future<List<Assignment>> getAllAssignments() async {
    final db = await _databaseHelper.database;

    final result = await db.query('assignments', orderBy: 'deadline ASC');

    return result.map(_fromMap).toList();
  }

  // Get assignment by ID.
  Future<Assignment?> getAssignmentById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'assignments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  // Get assignments belonging to a subject.
  Future<List<Assignment>> getAssignmentsBySubject(String subjectCode) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'assignments',
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
      orderBy: 'deadline ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Get assignments by status.
  Future<List<Assignment>> getAssignmentsByStatus(
    AssignmentStatus status,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'assignments',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'deadline ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Search assignments by title, subject code or description.
  // Optional filters can be applied at the same time.
  Future<List<Assignment>> searchAssignments(
    String keyword, {
    AssignmentStatus? status,
    String? subjectCode,
  }) async {
    final db = await _databaseHelper.database;

    final conditions = <String>[];
    final arguments = <Object?>[];

    final normalizedKeyword = keyword.trim();

    if (normalizedKeyword.isNotEmpty) {
      conditions.add('''
        (
          title LIKE ? COLLATE NOCASE
          OR subject_code LIKE ? COLLATE NOCASE
          OR description LIKE ? COLLATE NOCASE
        )
      ''');

      final pattern = '%$normalizedKeyword%';

      arguments.addAll([pattern, pattern, pattern]);
    }

    if (status != null) {
      conditions.add('status = ?');
      arguments.add(status.name);
    }

    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      conditions.add('subject_code = ?');
      arguments.add(subjectCode.trim());
    }

    final result = await db.query(
      'assignments',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'deadline ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Get overdue assignments.
  // An assignment is overdue only when it is incomplete
  // and its deadline has already passed.
  Future<List<Assignment>> getOverdueAssignments({DateTime? now}) async {
    final db = await _databaseHelper.database;
    final currentTime = (now ?? DateTime.now()).toIso8601String();

    final result = await db.query(
      'assignments',
      where: '''
        status = ?
        AND datetime(deadline) < datetime(?)
      ''',
      whereArgs: [AssignmentStatus.incomplete.name, currentTime],
      orderBy: 'deadline ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Get upcoming assignments.
  // Only incomplete assignments with future deadlines are returned.
  Future<List<Assignment>> getUpcomingAssignments({DateTime? now}) async {
    final db = await _databaseHelper.database;
    final currentTime = (now ?? DateTime.now()).toIso8601String();

    final result = await db.query(
      'assignments',
      where: '''
        status = ?
        AND datetime(deadline) >= datetime(?)
      ''',
      whereArgs: [AssignmentStatus.incomplete.name, currentTime],
      orderBy: 'deadline ASC',
    );

    return result.map(_fromMap).toList();
  }

  // Insert a new assignment.
  Future<int> insertAssignment(Assignment assignment) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'assignments',
      _toMap(assignment),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Update an existing assignment.
  Future<int> updateAssignment(Assignment assignment) async {
    final db = await _databaseHelper.database;

    return db.update(
      'assignments',
      _toMap(assignment),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  // Update assignment completion status.
  Future<int> updateAssignmentStatus(String id, AssignmentStatus status) async {
    final db = await _databaseHelper.database;

    return db.update(
      'assignments',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update assignment note.
  Future<int> updateAssignmentNote(String id, String? note) async {
    final db = await _databaseHelper.database;

    return db.update(
      'assignments',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete an assignment.
  // Its reminders are automatically deleted by ON DELETE CASCADE.
  Future<int> deleteAssignment(String id) async {
    final db = await _databaseHelper.database;

    return db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  // Get total number of assignments.
  Future<int> getAssignmentCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM assignments',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get number of completed assignments.
  Future<int> getCompletedAssignmentCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE status = ?
      ''',
      [AssignmentStatus.completed.name],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get number of incomplete assignments.
  Future<int> getIncompleteAssignmentCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM assignments
      WHERE status = ?
      ''',
      [AssignmentStatus.incomplete.name],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Calculate completion rate.
  // Return 0 when there are no assignments.
  Future<double> getCompletionRate() async {
    final total = await getAssignmentCount();

    if (total == 0) {
      return 0;
    }

    final completed = await getCompletedAssignmentCount();

    return completed / total * 100;
  }
}

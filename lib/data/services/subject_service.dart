import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../core/validators/subject_validator.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../repositories/subject_repository.dart';

class SubjectService {
  final SubjectRepository _repository;
  final DatabaseHelper _databaseHelper;

  SubjectService({
    SubjectRepository? repository,
    DatabaseHelper? databaseHelper,
  }) : _repository = repository ?? SubjectRepository(),
       _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Subject>> getAllSubjects() {
    return _repository.getAllSubjects();
  }

  Future<Subject?> getSubjectByCode(String code) {
    return _repository.getSubjectByCode(code);
  }

  Future<List<Subject>> searchSubjects(String keyword) {
    return _repository.searchSubjects(keyword);
  }

  Future<void> addSubject(Subject subject) async {
    final existing = await _repository.getAllSubjects();

    final error = SubjectValidator.validate(
      subjectCode: subject.subjectCode,
      name: subject.name,
      existingSubjects: existing,
    );

    if (error != null) {
      throw AppException(error.name);
    }

    await _repository.insertSubject(subject);
  }

  Future<void> updateSubject(Subject subject) async {
    final existing = await _repository.getAllSubjects();

    final error = SubjectValidator.validate(
      subjectCode: subject.subjectCode,
      name: subject.name,
      existingSubjects: existing,
      currentSubjectCode: subject.subjectCode,
    );

    if (error != null) {
      throw AppException(error.name);
    }

    final current = await _repository.getSubjectByCode(subject.subjectCode);

    if (current == null) {
      throw const AppException('subjectNotFound');
    }

    await _repository.updateSubject(subject);
  }

  Future<void> deleteSubject(String subjectCode) async {
    final db = await _databaseHelper.database;

    final assignments = await db.query(
      'assignments',
      columns: ['id'],
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
      limit: 1,
    );

    final schedules = await db.query(
      'schedules',
      columns: ['id'],
      where: 'subject_code = ?',
      whereArgs: [subjectCode],
      limit: 1,
    );

    if (assignments.isNotEmpty || schedules.isNotEmpty) {
      throw const AppException('subjectHasDependencies');
    }

    try {
      await _repository.deleteSubject(subjectCode);
    } on DatabaseException {
      throw const AppException('subjectDeleteFailed');
    }
  }
}

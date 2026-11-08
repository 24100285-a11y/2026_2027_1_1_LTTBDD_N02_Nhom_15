import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/validators/schedule_validator.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/subject_repository.dart';

class ScheduleService {
  final ScheduleRepository _repository;
  final SubjectRepository _subjectRepository;

  ScheduleService({
    ScheduleRepository? repository,
    SubjectRepository? subjectRepository,
  }) : _repository = repository ?? ScheduleRepository(),
       _subjectRepository = subjectRepository ?? SubjectRepository();

  Future<List<Schedule>> getAllSchedules() {
    return _repository.getAllSchedules();
  }

  Future<Schedule?> getScheduleById(String id) {
    return _repository.getScheduleById(id);
  }

  Future<List<Schedule>> getSchedulesBySubject(String subjectCode) {
    return _repository.getSchedulesBySubject(subjectCode);
  }

  Future<List<Schedule>> getSchedulesByWeekday(int weekday) {
    return _repository.getSchedulesByWeekday(weekday);
  }

  Future<List<Schedule>> getSchedulesForDate(DateTime date) {
    return _repository.getSchedulesForDate(date);
  }

  Future<void> _validateSchedule(
    Schedule schedule, {
    String? currentScheduleId,
  }) async {
    final List<Subject> subjects = await _subjectRepository.getAllSubjects();

    final schedules = await _repository.getAllSchedules();

    final error = ScheduleValidator.validate(
      subjectCode: schedule.subjectCode,
      weekday: schedule.weekday,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      existingSubjects: subjects,
      existingSchedules: schedules,
      currentScheduleId: currentScheduleId,
    );

    if (error != null) {
      throw AppException(error.name);
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _validateSchedule(schedule);
    await _repository.insertSchedule(schedule);
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final current = await _repository.getScheduleById(schedule.id);

    if (current == null) {
      throw const AppException('scheduleNotFound');
    }

    await _validateSchedule(schedule, currentScheduleId: schedule.id);

    await _repository.updateSchedule(schedule);
  }

  Future<void> deleteSchedule(String id) async {
    final current = await _repository.getScheduleById(id);

    if (current == null) {
      throw const AppException('scheduleNotFound');
    }

    await _repository.deleteSchedule(id);
  }

  Future<int> getScheduleCount() {
    return _repository.getScheduleCount();
  }

  // Convert TimeOfDay to a readable string.
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

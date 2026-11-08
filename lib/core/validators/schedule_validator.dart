import 'package:flutter/material.dart';

import '../../data/models/schedule.dart';
import '../../data/models/subject.dart';

enum ScheduleValidationError {
  emptySubjectCode,
  subjectNotFound,
  invalidWeekday,
  endTimeNotAfterStartTime,
  scheduleConflict,
}

class ScheduleValidator {
  static ScheduleValidationError? validate({
    required String subjectCode,
    required int weekday,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<Subject> existingSubjects,
    required List<Schedule> existingSchedules,
    String? currentScheduleId,
  }) {
    final normalizedCode = subjectCode.trim().toLowerCase();

    if (normalizedCode.isEmpty) {
      return ScheduleValidationError.emptySubjectCode;
    }

    final subjectExists = existingSubjects.any(
      (subject) => subject.subjectCode.trim().toLowerCase() == normalizedCode,
    );

    if (!subjectExists) {
      return ScheduleValidationError.subjectNotFound;
    }

    if (weekday < 1 || weekday > 7) {
      return ScheduleValidationError.invalidWeekday;
    }

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      return ScheduleValidationError.endTimeNotAfterStartTime;
    }

    final hasConflict = existingSchedules.any((schedule) {
      if (schedule.id == currentScheduleId) {
        return false;
      }

      if (schedule.weekday != weekday) {
        return false;
      }

      final existingStart =
          schedule.startTime.hour * 60 + schedule.startTime.minute;

      final existingEnd = schedule.endTime.hour * 60 + schedule.endTime.minute;

      return startMinutes < existingEnd && existingStart < endMinutes;
    });

    if (hasConflict) {
      return ScheduleValidationError.scheduleConflict;
    }

    return null;
  }
}

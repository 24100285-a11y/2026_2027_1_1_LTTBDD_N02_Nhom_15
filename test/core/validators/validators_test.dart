import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoc_tot/data/models/assignment.dart';
import 'package:hoc_tot/data/models/schedule.dart';
import 'package:hoc_tot/data/models/subject.dart';

import 'package:hoc_tot/core/validators/subject_validator.dart';
import 'package:hoc_tot/core/validators/assignment_validator.dart';
import 'package:hoc_tot/core/validators/schedule_validator.dart';
import 'package:hoc_tot/core/validators/reminder_validator.dart';

void main() {
  const subject = Subject(
    subjectCode: 'IT001',
    name: 'Lap trinh Dart',
    color: '#4F46E5',
  );

  final assignment = Assignment(
    id: 'A001',
    title: 'Bai tap Flutter',
    subjectCode: 'IT001',
    assignedDate: DateTime(2026, 11, 1),
    deadline: DateTime(2026, 11, 10, 23, 59),
    status: AssignmentStatus.incomplete,
  );

  group('SubjectValidator', () {
    test('Accepts valid subject', () {
      final result = SubjectValidator.validate(
        subjectCode: 'IT002',
        name: 'Lap trinh Java',
        existingSubjects: [subject],
      );

      expect(result, isNull);
    });

    test('Rejects empty subject code', () {
      final result = SubjectValidator.validate(
        subjectCode: ' ',
        name: 'Lap trinh Java',
        existingSubjects: [subject],
      );

      expect(result, SubjectValidationError.emptySubjectCode);
    });

    test('Rejects duplicate subject code', () {
      final result = SubjectValidator.validate(
        subjectCode: 'it001',
        name: 'Mon hoc khac',
        existingSubjects: [subject],
      );

      expect(result, SubjectValidationError.duplicateSubjectCode);
    });
  });

  group('AssignmentValidator', () {
    test('Accepts valid assignment', () {
      final result = AssignmentValidator.validate(
        title: 'Bai tap Flutter',
        subjectCode: 'IT001',
        assignedDate: DateTime(2026, 11, 1),
        deadline: DateTime(2026, 11, 10, 23, 59),
        existingSubjects: [subject],
      );

      expect(result, isNull);
    });

    test('Rejects assignment with missing subject', () {
      final result = AssignmentValidator.validate(
        title: 'Bai tap Flutter',
        subjectCode: 'IT999',
        assignedDate: DateTime(2026, 11, 1),
        deadline: DateTime(2026, 11, 10),
        existingSubjects: [subject],
      );

      expect(result, AssignmentValidationError.subjectNotFound);
    });

    test('Rejects deadline before assigned date', () {
      final result = AssignmentValidator.validate(
        title: 'Bai tap Flutter',
        subjectCode: 'IT001',
        assignedDate: DateTime(2026, 11, 10),
        deadline: DateTime(2026, 11, 9, 23, 59),
        existingSubjects: [subject],
      );

      expect(result, AssignmentValidationError.deadlineBeforeAssignedDate);
    });
  });

  group('ScheduleValidator', () {
    test('Accepts valid schedule', () {
      final result = ScheduleValidator.validate(
        subjectCode: 'IT001',
        weekday: 2,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        existingSubjects: [subject],
        existingSchedules: [],
      );

      expect(result, isNull);
    });

    test('Rejects overlapping schedules', () {
      final existingSchedule = Schedule(
        id: 'S001',
        subjectCode: 'IT001',
        weekday: 2,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );

      final result = ScheduleValidator.validate(
        subjectCode: 'IT001',
        weekday: 2,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        existingSubjects: [subject],
        existingSchedules: [existingSchedule],
      );

      expect(result, ScheduleValidationError.scheduleConflict);
    });

    test('Allows schedules that touch at endpoints', () {
      final existingSchedule = Schedule(
        id: 'S001',
        subjectCode: 'IT001',
        weekday: 2,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 0),
      );

      final result = ScheduleValidator.validate(
        subjectCode: 'IT001',
        weekday: 2,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        existingSubjects: [subject],
        existingSchedules: [existingSchedule],
      );

      expect(result, isNull);
    });
  });

  group('ReminderValidator', () {
    test('Accepts reminder linked to existing assignment', () {
      final result = ReminderValidator.validate(
        id: 'R001',
        assignmentId: 'A001',
        existingAssignments: [assignment],
      );

      expect(result, isNull);
    });

    test('Rejects reminder linked to missing assignment', () {
      final result = ReminderValidator.validate(
        id: 'R001',
        assignmentId: 'A999',
        existingAssignments: [assignment],
      );

      expect(result, ReminderValidationError.assignmentNotFound);
    });
  });
}

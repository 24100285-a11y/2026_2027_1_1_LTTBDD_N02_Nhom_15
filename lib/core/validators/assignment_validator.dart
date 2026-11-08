import '../../data/models/subject.dart';

enum AssignmentValidationError {
  emptyTitle,
  emptySubjectCode,
  subjectNotFound,
  deadlineBeforeAssignedDate,
}

class AssignmentValidator {
  static AssignmentValidationError? validate({
    required String title,
    required String subjectCode,
    required DateTime assignedDate,
    required DateTime deadline,
    required List<Subject> existingSubjects,
  }) {
    if (title.trim().isEmpty) {
      return AssignmentValidationError.emptyTitle;
    }

    final normalizedCode = subjectCode.trim().toLowerCase();

    if (normalizedCode.isEmpty) {
      return AssignmentValidationError.emptySubjectCode;
    }

    final subjectExists = existingSubjects.any(
      (subject) => subject.subjectCode.trim().toLowerCase() == normalizedCode,
    );

    if (!subjectExists) {
      return AssignmentValidationError.subjectNotFound;
    }

    final assignedDay = DateTime(
      assignedDate.year,
      assignedDate.month,
      assignedDate.day,
    );

    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDay.isBefore(assignedDay)) {
      return AssignmentValidationError.deadlineBeforeAssignedDate;
    }

    return null;
  }
}

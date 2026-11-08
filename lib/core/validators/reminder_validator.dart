import '../../data/models/assignment.dart';

enum ReminderValidationError {
  emptyReminderId,
  emptyAssignmentId,
  assignmentNotFound,
}

class ReminderValidator {
  static ReminderValidationError? validate({
    required String id,
    required String assignmentId,
    required List<Assignment> existingAssignments,
  }) {
    if (id.trim().isEmpty) {
      return ReminderValidationError.emptyReminderId;
    }

    if (assignmentId.trim().isEmpty) {
      return ReminderValidationError.emptyAssignmentId;
    }

    final assignmentExists = existingAssignments.any(
      (assignment) => assignment.id == assignmentId,
    );

    if (!assignmentExists) {
      return ReminderValidationError.assignmentNotFound;
    }

    return null;
  }
}

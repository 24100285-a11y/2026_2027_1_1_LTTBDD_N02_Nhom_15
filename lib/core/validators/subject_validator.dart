import '../../data/models/subject.dart';

enum SubjectValidationError {
  emptySubjectCode,
  emptyName,
  duplicateSubjectCode,
}

class SubjectValidator {
  static SubjectValidationError? validate({
    required String subjectCode,
    required String name,
    required List<Subject> existingSubjects,
    String? currentSubjectCode,
  }) {
    final normalizedCode = subjectCode.trim().toLowerCase();

    if (normalizedCode.isEmpty) {
      return SubjectValidationError.emptySubjectCode;
    }

    if (name.trim().isEmpty) {
      return SubjectValidationError.emptyName;
    }

    final currentCode = currentSubjectCode?.trim().toLowerCase();

    final isDuplicate = existingSubjects.any((subject) {
      final existingCode = subject.subjectCode.trim().toLowerCase();

      return existingCode == normalizedCode && existingCode != currentCode;
    });

    if (isDuplicate) {
      return SubjectValidationError.duplicateSubjectCode;
    }

    return null;
  }
}

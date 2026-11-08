enum AssignmentStatus { completed, incomplete }

class Assignment {
  final String id;
  final String title;
  final String subjectCode;
  final DateTime assignedDate;
  final DateTime deadline;
  final String? description;
  final String? note;
  final AssignmentStatus status;

  const Assignment({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.assignedDate,
    required this.deadline,
    this.description,
    this.note,
    required this.status,
  });

  Assignment copyWith({
    String? id,
    String? title,
    String? subjectCode,
    DateTime? assignedDate,
    DateTime? deadline,
    String? description,
    String? note,
    AssignmentStatus? status,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectCode: subjectCode ?? this.subjectCode,
      assignedDate: assignedDate ?? this.assignedDate,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }

  bool isOverdueAt(DateTime now) {
    return status == AssignmentStatus.incomplete && now.isAfter(deadline);
  }
}

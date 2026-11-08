enum ReminderType { oneDayBefore, oneHourBefore }

class Reminder {
  final String id;
  final String assignmentId;
  final ReminderType reminderType;
  final DateTime scheduledAt;
  final int notificationId;
  final bool isScheduled;

  const Reminder({
    required this.id,
    required this.assignmentId,
    required this.reminderType,
    required this.scheduledAt,
    required this.notificationId,
    required this.isScheduled,
  });

  Reminder copyWith({
    String? id,
    String? assignmentId,
    ReminderType? reminderType,
    DateTime? scheduledAt,
    int? notificationId,
    bool? isScheduled,
  }) {
    return Reminder(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      reminderType: reminderType ?? this.reminderType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      isScheduled: isScheduled ?? this.isScheduled,
    );
  }
}

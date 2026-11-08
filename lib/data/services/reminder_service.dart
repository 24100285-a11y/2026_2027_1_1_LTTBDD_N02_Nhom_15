import '../../core/errors/app_exception.dart';
import '../../core/validators/reminder_validator.dart';
import '../models/assignment.dart';
import '../models/reminder.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/reminder_repository.dart';

class ReminderService {
  final ReminderRepository _repository;
  final AssignmentRepository _assignmentRepository;

  ReminderService({
    ReminderRepository? repository,
    AssignmentRepository? assignmentRepository,
  }) : _repository = repository ?? ReminderRepository(),
       _assignmentRepository = assignmentRepository ?? AssignmentRepository();

  // Lấy toàn bộ lịch nhắc.
  Future<List<Reminder>> getAllReminders() {
    return _repository.getAllReminders();
  }

  // Lấy lịch nhắc theo ID.
  Future<Reminder?> getReminderById(String id) {
    return _repository.getReminderById(id);
  }

  // Lấy các lịch nhắc của một bài tập.
  Future<List<Reminder>> getRemindersByAssignment(String assignmentId) {
    return _repository.getRemindersByAssignment(assignmentId);
  }

  // Lấy lịch nhắc chưa được lên lịch trên thiết bị.
  Future<List<Reminder>> getPendingReminders() {
    return _repository.getPendingReminders();
  }

  // Lấy lịch nhắc đã được lên lịch.
  Future<List<Reminder>> getScheduledReminders() {
    return _repository.getScheduledReminders();
  }

  // Kiểm tra lịch nhắc có bài tập hợp lệ hay không.
  Future<void> _validateReminder(Reminder reminder) async {
    final assignments = await _assignmentRepository.getAllAssignments();

    final error = ReminderValidator.validate(
      id: reminder.id,
      assignmentId: reminder.assignmentId,
      existingAssignments: assignments,
    );

    if (error != null) {
      throw AppException(error.name);
    }
  }

  // Thêm lịch nhắc.
  Future<void> addReminder(Reminder reminder) async {
    await _validateReminder(reminder);
    await _repository.insertReminder(reminder);
  }

  // Cập nhật lịch nhắc.
  Future<void> updateReminder(Reminder reminder) async {
    final current = await _repository.getReminderById(reminder.id);

    if (current == null) {
      throw const AppException('reminderNotFound');
    }

    await _validateReminder(reminder);
    await _repository.updateReminder(reminder);
  }

  // Cập nhật trạng thái lên lịch thông báo.
  Future<void> updateScheduleStatus(String id, bool isScheduled) async {
    final current = await _repository.getReminderById(id);

    if (current == null) {
      throw const AppException('reminderNotFound');
    }

    await _repository.updateReminderScheduleStatus(id, isScheduled);
  }

  // Xóa một lịch nhắc.
  Future<void> deleteReminder(String id) {
    return _repository.deleteReminder(id);
  }

  // Xóa toàn bộ lịch nhắc của một bài tập.
  Future<void> deleteRemindersByAssignment(String assignmentId) {
    return _repository.deleteRemindersByAssignment(assignmentId);
  }

  // Đếm số lượng lịch nhắc.
  Future<int> getReminderCount() {
    return _repository.getReminderCount();
  }

  // Tạo các lịch nhắc mặc định cho bài tập.
  //
  // Quy tắc:
  // 1. Nhắc trước hạn 1 ngày nếu mốc này còn ở tương lai.
  // 2. Nhắc trước hạn 1 giờ nếu mốc này còn ở tương lai.
  // 3. Không tạo lịch nhắc đã quá thời điểm.
  // 4. Không tạo lịch nhắc cho bài tập đã hoàn thành.
  // 5. Không tạo trùng lịch nhắc cho cùng một bài tập.
  Future<void> createDefaultReminders(
    Assignment assignment, {
    required int oneDayNotificationId,
    required int oneHourNotificationId,
  }) async {
    // Không tạo lịch nhắc cho bài tập đã hoàn thành.
    if (assignment.status == AssignmentStatus.completed) {
      return;
    }

    // Kiểm tra lịch nhắc đã tồn tại.
    final existing = await getRemindersByAssignment(assignment.id);

    if (existing.isNotEmpty) {
      throw const AppException('remindersAlreadyExist');
    }

    final now = DateTime.now();

    // Tính hai mốc nhắc.
    final oneDayBefore = assignment.deadline.subtract(const Duration(days: 1));

    final oneHourBefore = assignment.deadline.subtract(
      const Duration(hours: 1),
    );

    // Chỉ tạo mốc nhắc một ngày nếu vẫn còn trong tương lai.
    if (oneDayBefore.isAfter(now)) {
      final reminder = Reminder(
        id: '${assignment.id}_1day',
        assignmentId: assignment.id,
        reminderType: ReminderType.oneDayBefore,
        scheduledAt: oneDayBefore,
        notificationId: oneDayNotificationId,
        isScheduled: false,
      );

      await addReminder(reminder);
    }

    // Chỉ tạo mốc nhắc một giờ nếu vẫn còn trong tương lai.
    if (oneHourBefore.isAfter(now)) {
      final reminder = Reminder(
        id: '${assignment.id}_1hour',
        assignmentId: assignment.id,
        reminderType: ReminderType.oneHourBefore,
        scheduledAt: oneHourBefore,
        notificationId: oneHourNotificationId,
        isScheduled: false,
      );

      await addReminder(reminder);
    }
  }
}

import 'package:flutter/foundation.dart';

import '../models/assignment.dart';
import '../repositories/assignment_repository.dart';
import 'notification_service.dart';
import 'reminder_service.dart';

class AssignmentReminderManager {
  final AssignmentRepository _assignmentRepository;
  final ReminderService _reminderService;
  final NotificationService _notificationService;

  static int _lastGeneratedNotificationId = 0;

  AssignmentReminderManager({
    AssignmentRepository? assignmentRepository,
    ReminderService? reminderService,
    NotificationService? notificationService,
  }) : _assignmentRepository = assignmentRepository ?? AssignmentRepository(),
       _reminderService = reminderService ?? ReminderService(),
       _notificationService =
           notificationService ?? NotificationService.instance;

  // Tạo ID thông báo duy nhất trong quá trình chạy ứng dụng.
  int _generateNotificationId() {
    const maxId = 0x3FFFFFFF;

    final currentId = DateTime.now().microsecondsSinceEpoch & maxId;

    if (currentId > _lastGeneratedNotificationId) {
      _lastGeneratedNotificationId = currentId;
    } else {
      _lastGeneratedNotificationId++;

      if (_lastGeneratedNotificationId > maxId) {
        _lastGeneratedNotificationId = 1;
      }
    }

    return _lastGeneratedNotificationId;
  }

  // Yêu cầu quyền thông báo.
  Future<bool> requestPermission() {
    return _notificationService.requestPermission();
  }

  // Tạo và đồng bộ lịch nhắc cho một bài tập.
  Future<void> syncAssignmentReminders(
    Assignment assignment, {
    required bool isVietnamese,
  }) async {
    // Hủy toàn bộ lịch cũ trước khi tạo lịch mới.
    await cancelAssignmentReminders(assignment.id);

    // Không nhắc những bài tập đã hoàn thành.
    if (assignment.status == AssignmentStatus.completed) {
      return;
    }

    try {
      // ReminderService chỉ lưu những mốc nhắc còn ở tương lai.
      await _reminderService.createDefaultReminders(
        assignment,
        oneDayNotificationId: _generateNotificationId(),
        oneHourNotificationId: _generateNotificationId(),
      );

      final reminders = await _reminderService.getRemindersByAssignment(
        assignment.id,
      );

      final now = DateTime.now();

      for (final reminder in reminders) {
        // Xóa mốc nhắc đã hết hiệu lực.
        if (!reminder.scheduledAt.isAfter(now)) {
          await _reminderService.deleteReminder(reminder.id);
          continue;
        }

        // Đăng ký thông báo với Android.
        await _notificationService.scheduleReminder(
          reminder: reminder,
          assignmentTitle: assignment.title,
          isVietnamese: isVietnamese,
        );

        // Chỉ đánh dấu đã lên lịch sau khi đăng ký thành công.
        await _reminderService.updateScheduleStatus(reminder.id, true);
      }
    } catch (error) {
      debugPrint('Could not sync reminders for ${assignment.id}: $error');

      // Dọn những lịch đã tạo dở.
      try {
        await cancelAssignmentReminders(assignment.id);
      } catch (cleanupError) {
        debugPrint(
          'Could not clean up reminders for ${assignment.id}: '
          '$cleanupError',
        );
      }

      rethrow;
    }
  }

  // Hủy tất cả lịch nhắc của một bài tập.
  Future<void> cancelAssignmentReminders(String assignmentId) async {
    final reminders = await _reminderService.getRemindersByAssignment(
      assignmentId,
    );

    for (final reminder in reminders) {
      try {
        await _notificationService.cancelReminder(reminder.notificationId);
      } catch (error) {
        debugPrint(
          'Could not cancel notification '
          '${reminder.notificationId}: $error',
        );
      }
    }

    // Xóa các bản ghi nhắc hạn trong SQLite.
    await _reminderService.deleteRemindersByAssignment(assignmentId);
  }

  // Khôi phục thông báo đã lưu khi mở ứng dụng.
  Future<void> restorePendingReminders({required bool isVietnamese}) async {
    final assignments = await _assignmentRepository.getAllAssignments();

    final reminders = await _reminderService.getAllReminders();

    final pendingNotifications = await _notificationService
        .getPendingNotifications();

    // Tra cứu bài tập theo ID.
    final assignmentsById = {
      for (final assignment in assignments) assignment.id: assignment,
    };

    // Các ID thông báo Android đang chờ.
    final pendingIds = {
      for (final notification in pendingNotifications) notification.id,
    };

    final cleanedAssignmentIds = <String>{};
    final now = DateTime.now();

    for (final reminder in reminders) {
      final assignment = assignmentsById[reminder.assignmentId];

      // Bài tập không tồn tại hoặc đã hoàn thành.
      if (assignment == null ||
          assignment.status == AssignmentStatus.completed) {
        try {
          await _notificationService.cancelReminder(reminder.notificationId);
        } catch (error) {
          debugPrint('Could not cancel invalid reminder: $error');
        }

        if (cleanedAssignmentIds.add(reminder.assignmentId)) {
          await _reminderService.deleteRemindersByAssignment(
            reminder.assignmentId,
          );
        }

        continue;
      }

      // Không khôi phục mốc nhắc đã qua.
      if (!reminder.scheduledAt.isAfter(now)) {
        try {
          await _notificationService.cancelReminder(reminder.notificationId);
        } catch (error) {
          debugPrint('Could not cancel expired reminder: $error');
        }

        await _reminderService.deleteReminder(reminder.id);
        continue;
      }

      // Thông báo vẫn tồn tại trong Android.
      if (pendingIds.contains(reminder.notificationId)) {
        if (!reminder.isScheduled) {
          await _reminderService.updateScheduleStatus(reminder.id, true);
        }

        continue;
      }

      // Thông báo không còn trong Android:
      // khôi phục từ dữ liệu SQLite.
      try {
        await _notificationService.scheduleReminder(
          reminder: reminder,
          assignmentTitle: assignment.title,
          isVietnamese: isVietnamese,
        );

        await _reminderService.updateScheduleStatus(reminder.id, true);
      } catch (error) {
        debugPrint('Could not restore reminder ${reminder.id}: $error');
      }
    }
  }

  // Đồng bộ lại lịch nhắc cho tất cả bài tập.
  Future<void> syncAllReminders({required bool isVietnamese}) async {
    final assignments = await _assignmentRepository.getAllAssignments();

    for (final assignment in assignments) {
      try {
        await syncAssignmentReminders(assignment, isVietnamese: isVietnamese);
      } catch (error) {
        debugPrint('Could not sync reminders for ${assignment.id}: $error');
      }
    }
  }
}

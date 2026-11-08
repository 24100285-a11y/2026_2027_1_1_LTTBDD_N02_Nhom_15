import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _channelId = 'hoc_tot_assignment_reminders';
  static const String _channelName = 'Nhắc hạn bài tập';
  static const String _channelDescription =
      'Thông báo nhắc nhở khi bài tập sắp đến hạn';

  // Khởi tạo plugin và múi giờ của thiết bị.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Khởi tạo dữ liệu múi giờ.
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      debugPrint('Could not get device timezone: $error');

      // Múi giờ dự phòng cho Việt Nam.
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    // Cấu hình biểu tượng thông báo Android.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Không tự động hỏi quyền iOS/macOS khi khởi tạo.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initializationSettings);

    _isInitialized = true;
  }

  // Yêu cầu người dùng cấp quyền thông báo trên Android.
  Future<bool> requestPermission() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final result = await android?.requestNotificationsPermission();

    return result ?? false;
  }

  // Kiểm tra ứng dụng có được phép gửi thông báo hay không.
  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.areNotificationsEnabled() ?? false;
  }

  // Tạo nội dung thông báo theo loại nhắc hạn.
  String _getNotificationTitle({required bool isVietnamese}) {
    return isVietnamese ? 'Nhắc nhở bài tập' : 'Assignment reminder';
  }

  String _getNotificationBody({
    required Reminder reminder,
    required String assignmentTitle,
    required bool isVietnamese,
  }) {
    if (reminder.reminderType == ReminderType.oneDayBefore) {
      return isVietnamese
          ? 'Bài tập "$assignmentTitle" sẽ đến hạn trong 1 ngày nữa.'
          : 'Assignment "$assignmentTitle" is due in 1 day.';
    }

    return isVietnamese
        ? 'Bài tập "$assignmentTitle" sẽ đến hạn trong 1 giờ nữa.'
        : 'Assignment "$assignmentTitle" is due in 1 hour.';
  }

  // Lên lịch một thông báo.
  Future<void> scheduleReminder({
    required Reminder reminder,
    required String assignmentTitle,
    required bool isVietnamese,
  }) async {
    await initialize();

    // Không lên lịch nếu thời điểm thông báo đã qua.
    if (!reminder.scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: _getNotificationTitle(isVietnamese: isVietnamese),
      body: _getNotificationBody(
        reminder: reminder,
        assignmentTitle: assignmentTitle,
        isVietnamese: isVietnamese,
      ),
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.assignmentId,
    );
  }

  // Hủy một thông báo theo ID.
  Future<void> cancelReminder(int notificationId) async {
    await initialize();

    await _plugin.cancel(id: notificationId);
  }

  // Hủy tất cả thông báo.
  Future<void> cancelAll() async {
    await initialize();

    await _plugin.cancelAll();
  }

  // Lấy danh sách thông báo đang chờ hiển thị.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();

    return _plugin.pendingNotificationRequests();
  }
}

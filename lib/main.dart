import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/models/app_settings.dart';
import 'data/services/assignment_reminder_manager.dart';
import 'data/services/notification_service.dart';
import 'data/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bước 1: Khởi tạo hệ thống thông báo.
  try {
    await NotificationService.instance.initialize();
  } catch (error) {
    debugPrint('Notification initialization failed: $error');
  }

  // Bước 2: Đọc ngôn ngữ đã lưu trong SQLite.
  var language = AppLanguage.vi;

  try {
    language = await SettingsService().getLanguage();
  } catch (error) {
    debugPrint('Could not load language settings: $error');
  }

  // Bước 3: Khôi phục những thông báo đã lưu.
  try {
    await AssignmentReminderManager().restorePendingReminders(
      isVietnamese: language == AppLanguage.vi,
    );
  } catch (error) {
    debugPrint('Could not restore reminders: $error');
  }

  // Bước 4: Khởi chạy giao diện ứng dụng.
  runApp(const HocTotApp());
}

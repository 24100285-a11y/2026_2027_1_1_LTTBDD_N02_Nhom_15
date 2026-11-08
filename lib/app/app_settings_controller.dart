import 'package:flutter/material.dart';

import '../data/models/app_settings.dart';
import '../data/services/assignment_reminder_manager.dart';
import '../data/services/settings_service.dart';

class AppSettingsController extends ChangeNotifier {
  final SettingsService _settingsService;
  final AssignmentReminderManager _reminderManager;

  AppLanguage _language = AppLanguage.vi;
  bool _isLoaded = false;
  bool _isChangingLanguage = false;

  AppSettingsController({
    SettingsService? settingsService,
    AssignmentReminderManager? reminderManager,
  }) : _settingsService = settingsService ?? SettingsService(),
       _reminderManager = reminderManager ?? AssignmentReminderManager();

  AppLanguage get language => _language;

  Locale get locale => Locale(_language.name);

  bool get isLoaded => _isLoaded;

  bool get isChangingLanguage => _isChangingLanguage;

  // Đọc cài đặt đã lưu trong SQLite.
  Future<void> loadSettings() async {
    final settings = await _settingsService.getSettings();

    _language = settings.language;
    _isLoaded = true;

    notifyListeners();
  }

  // Thay đổi ngôn ngữ ứng dụng và đồng bộ thông báo.
  Future<void> changeLanguage(AppLanguage language) async {
    if (_language == language || _isChangingLanguage) {
      return;
    }

    _isChangingLanguage = true;
    notifyListeners();

    try {
      // Lưu ngôn ngữ mới vào SQLite.
      await _settingsService.changeLanguage(language);

      // Cập nhật ngôn ngữ giao diện.
      _language = language;
      notifyListeners();

      // Đồng bộ nội dung thông báo theo ngôn ngữ mới.
      try {
        await _reminderManager.syncAllReminders(
          isVietnamese: language == AppLanguage.vi,
        );
      } catch (error) {
        debugPrint('Could not synchronize reminder language: $error');
      }
    } finally {
      _isChangingLanguage = false;
      notifyListeners();
    }
  }
}

// Cung cấp AppSettingsController cho các màn hình bên trong ứng dụng.
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();

    assert(scope != null, 'AppSettingsScope was not found in the widget tree.');

    return scope!.notifier!;
  }
}

import 'package:flutter/material.dart';

import '../../app/app_settings_controller.dart';
import '../../data/models/app_settings.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _text(BuildContext context, String vi, String en) {
    final language = Localizations.localeOf(context).languageCode;
    return language == 'vi' ? vi : en;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppSettingsScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(context, 'Cài đặt', 'Settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // LANGUAGE SETTINGS
          _buildSectionTitle(context, _text(context, 'Ngôn ngữ', 'Language')),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                RadioListTile<AppLanguage>(
                  value: AppLanguage.vi,
                  groupValue: controller.language,
                  onChanged: controller.isChangingLanguage
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.changeLanguage(value);
                          }
                        },
                  title: const Text(
                    'Tiếng Việt',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Vietnamese'),
                  secondary: const Text('🇻🇳', style: TextStyle(fontSize: 25)),
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<AppLanguage>(
                  value: AppLanguage.en,
                  groupValue: controller.language,
                  onChanged: controller.isChangingLanguage
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.changeLanguage(value);
                          }
                        },
                  title: const Text(
                    'English',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('English language'),
                  secondary: const Text('🇬🇧', style: TextStyle(fontSize: 25)),
                  activeColor: theme.colorScheme.primary,
                ),
                if (controller.isChangingLanguage)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // NOTIFICATION SETTINGS
          _buildSectionTitle(
            context,
            _text(context, 'Thông báo', 'Notifications'),
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                _text(context, 'Cài đặt thông báo', 'Notification settings'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _text(
                  context,
                  'Quản lý quyền và lịch nhắc bài tập',
                  'Manage permissions and assignment reminders',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // APP INFORMATION
          _buildSectionTitle(
            context,
            _text(context, 'Thông tin ứng dụng', 'About application'),
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(
                    _text(context, 'Tên ứng dụng', 'Application name'),
                  ),
                  subtitle: const Text('Học Tốt'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(_text(context, 'Phiên bản', 'Version')),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(
                    _text(context, 'Lưu trữ dữ liệu', 'Data storage'),
                  ),
                  subtitle: Text(
                    _text(
                      context,
                      'SQLite trên thiết bị',
                      'Local SQLite database',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Text(
              'Học Tốt • Study Planner',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

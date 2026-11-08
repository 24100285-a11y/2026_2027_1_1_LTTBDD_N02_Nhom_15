import 'package:flutter/material.dart';

import '../../data/services/assignment_reminder_manager.dart';
import '../../data/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService.instance;

  final AssignmentReminderManager _reminderManager =
      AssignmentReminderManager();

  bool _isLoading = true;
  bool _isEnabled = false;
  bool _isRequesting = false;

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  @override
  void initState() {
    super.initState();

    // Theo dõi trạng thái hoạt động của ứng dụng.
    WidgetsBinding.instance.addObserver(this);

    _loadNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kiểm tra lại quyền khi người dùng quay về ứng dụng.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationStatus();
    }
  }

  // Đọc trạng thái quyền thông báo từ Android.
  Future<void> _loadNotificationStatus() async {
    try {
      final enabled = await _notificationService.areNotificationsEnabled();

      if (!mounted) return;

      setState(() {
        _isEnabled = enabled;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('Could not check notification permission: $error');
    }
  }

  // Yêu cầu quyền thông báo.
  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final granted = await _notificationService.requestPermission();

      if (!mounted) return;

      if (granted) {
        // Khôi phục lịch nhắc sau khi được cấp quyền.
        await _reminderManager.restorePendingReminders(
          isVietnamese: _isVietnamese,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Đã cấp quyền thông báo thành công.',
                'Notification permission granted.',
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Quyền thông báo chưa được cấp. '
                    'Bạn có thể bật trong Cài đặt Android.',
                'Notification permission was not granted. '
                    'You can enable it in Android Settings.',
              ),
            ),
          ),
        );
      }

      await _loadNotificationStatus();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Không thể yêu cầu quyền thông báo.',
              'Could not request notification permission.',
            ),
          ),
        ),
      );

      debugPrint('Notification permission error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  // Làm mới trạng thái quyền.
  Future<void> _refreshStatus() async {
    await _loadNotificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('Cài đặt thông báo', 'Notification settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPermissionCard(theme),
                  const SizedBox(height: 20),
                  _buildReminderCard(theme),
                  const SizedBox(height: 20),
                  _buildInformationCard(theme),
                ],
              ),
            ),
    );
  }

  // Thẻ hiển thị quyền thông báo.
  Widget _buildPermissionCard(ThemeData theme) {
    final statusColor = _isEnabled ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: statusColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('Quyền thông báo', 'Notification permission'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isEnabled
                          ? _text('Đang bật', 'Enabled')
                          : _text('Đang tắt', 'Disabled'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isEnabled
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _text(
              'Cho phép Học Tốt gửi thông báo để nhắc bạn '
                  'hoàn thành bài tập đúng hạn.',
              'Allow Hoc Tot to send notifications '
                  'to remind you about assignment deadlines.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _isEnabled
                ? OutlinedButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_text('Kiểm tra lại', 'Refresh status')),
                  )
                : FilledButton.icon(
                    onPressed: _isRequesting ? null : _requestPermission,
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(
                      _isRequesting
                          ? _text('Đang xử lý...', 'Processing...')
                          : _text(
                              'Cấp quyền thông báo',
                              'Grant notification permission',
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Thẻ hiển thị các mốc nhắc hạn.
  Widget _buildReminderCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Lịch nhắc hạn bài tập', 'Assignment reminder schedule'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _buildReminderItem(
            theme,
            Icons.calendar_today_rounded,
            _text('Trước hạn 1 ngày', '1 day before deadline'),
            _text(
              'Nhắc bạn chuẩn bị hoàn thành bài tập.',
              'A reminder to prepare your assignment.',
            ),
          ),
          const SizedBox(height: 18),
          _buildReminderItem(
            theme,
            Icons.alarm_rounded,
            _text('Trước hạn 1 giờ', '1 hour before deadline'),
            _text(
              'Nhắc bạn kiểm tra và hoàn thành bài tập.',
              'A reminder to check and complete your assignment.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 23),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Thẻ giải thích quy tắc thông báo.
  Widget _buildInformationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _text(
                'Thông báo chỉ được tạo cho bài tập chưa hoàn thành. '
                    'Khi bạn đánh dấu bài tập là đã hoàn thành, '
                    'các lịch nhắc tương ứng sẽ được hủy.',
                'Reminders are only created for incomplete assignments. '
                    'When an assignment is marked as completed, '
                    'its scheduled reminders are canceled.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

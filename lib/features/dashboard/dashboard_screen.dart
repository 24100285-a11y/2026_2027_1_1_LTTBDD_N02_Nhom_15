import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../settings/notification_settings_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../data/models/assignment.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/subject_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SubjectService _subjectService = SubjectService();
  final AssignmentService _assignmentService = AssignmentService();

  bool _isLoading = true;
  String? _errorMessage;

  int _subjectCount = 0;
  int _assignmentCount = 0;
  int _completedCount = 0;
  double _completionRate = 0;

  List<Assignment> _upcomingAssignments = [];

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final subjects = await _subjectService.getAllSubjects();
      final assignments = await _assignmentService.getAllAssignments();
      final completed = await _assignmentService.getCompletedCount();
      final completionRate = await _assignmentService.getCompletionRate();
      final upcoming = await _assignmentService.getUpcomingAssignments();

      upcoming.sort((a, b) => a.deadline.compareTo(b.deadline));

      if (!mounted) return;

      setState(() {
        _subjectCount = subjects.length;
        _assignmentCount = assignments.length;
        _completedCount = completed;
        _completionRate = completionRate;
        _upcomingAssignments = upcoming.take(5).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day) {
      return _text('Hôm nay', 'Today');
    }

    if (difference.inDays == 1 ||
        (deadline.day == now.add(const Duration(days: 1)).day &&
            deadline.month == now.add(const Duration(days: 1)).month &&
            deadline.year == now.add(const Duration(days: 1)).year)) {
      return _text('Ngày mai', 'Tomorrow');
    }

    return _formatDate(deadline);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Mở màn hình Cài đặt.
          IconButton(
            tooltip: _text('Cài đặt', 'Settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),

          // Mở cài đặt thông báo.
          IconButton(
            tooltip: _text('Cài đặt thông báo', 'Notification settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),

          // Làm mới Dashboard.
          IconButton(
            tooltip: _text('Làm mới', 'Refresh'),
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView(theme)
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _buildGreeting(theme, now),
                  const SizedBox(height: 24),
                  _buildStatistics(theme),
                  const SizedBox(height: 24),
                  _buildProgressCard(theme),
                  const SizedBox(height: 28),
                  _buildUpcomingHeader(theme),
                  const SizedBox(height: 12),
                  _buildUpcomingList(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting(ThemeData theme, DateTime now) {
    final dateText = DateFormat(
      'EEEE, dd/MM/yyyy',
      _isVietnamese ? 'vi' : 'en',
    ).format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Xin chào! 👋', 'Hello! 👋'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _text(
            'Cùng bắt đầu một ngày học tập hiệu quả nhé.',
            'Let’s make today a productive study day.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 7),
            Text(
              dateText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          title: _text('Môn học', 'Subjects'),
          value: _subjectCount.toString(),
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF4F46E5),
        ),
        _StatCard(
          title: _text('Tổng bài tập', 'Assignments'),
          value: _assignmentCount.toString(),
          icon: Icons.assignment_rounded,
          color: const Color(0xFF0891B2),
        ),
        _StatCard(
          title: _text('Đã hoàn thành', 'Completed'),
          value: _completedCount.toString(),
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF16A34A),
        ),
        _StatCard(
          title: _text('Chưa hoàn thành', 'Incomplete'),
          value: (_assignmentCount - _completedCount).toString(),
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final percentage = (_completionRate * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF7770EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _text('Tiến độ học tập', 'Study progress'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Bạn đã hoàn thành $_completedCount trên $_assignmentCount bài tập.',
              'You have completed $_completedCount of $_assignmentCount assignments.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _text('Bài tập sắp đến hạn', 'Upcoming assignments'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '${_upcomingAssignments.length}/5',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(ThemeData theme) {
    if (_upcomingAssignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _text('Chưa có bài tập sắp đến hạn', 'No upcoming assignments'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _text(
                'Các bài tập cần hoàn thành sẽ xuất hiện ở đây.',
                'Assignments that need attention will appear here.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _upcomingAssignments.map((assignment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_text('Môn', 'Subject')}: ${assignment.subjectCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDeadline(assignment.deadline),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                'Không thể tải dữ liệu Dashboard',
                'Unable to load dashboard data',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Thử lại', 'Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

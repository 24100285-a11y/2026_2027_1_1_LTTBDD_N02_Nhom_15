import 'package:flutter/material.dart';

import '../../data/models/assignment.dart';
import '../../data/services/assignment_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AssignmentService _assignmentService = AssignmentService();

  bool _isLoading = true;
  String? _errorMessage;

  int _total = 0;
  int _completed = 0;
  int _incomplete = 0;
  int _overdue = 0;
  double _completionRate = 0;

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _assignmentService.getTotalCount(),
        _assignmentService.getCompletedCount(),
        _assignmentService.getIncompleteCount(),
        _assignmentService.getCompletionRate(),
        _assignmentService.getAllAssignments(),
      ]);

      final assignments = results[4] as List<Assignment>;
      final now = DateTime.now();

      final overdueCount = assignments
          .where((assignment) => assignment.isOverdueAt(now))
          .length;

      if (!mounted) return;

      setState(() {
        _total = results[0] as int;
        _completed = results[1] as int;
        _incomplete = results[2] as int;
        _completionRate = results[3] as double;
        _overdue = overdueCount;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('Thống kê học tập', 'Study statistics'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _text('Làm mới', 'Refresh'),
            onPressed: _loadStatistics,
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
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildOverview(theme),
                  const SizedBox(height: 24),
                  _buildProgressSection(theme),
                  const SizedBox(height: 24),
                  _buildStatusSection(theme),
                  const SizedBox(height: 24),
                  _buildOverdueSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Tổng quan', 'Overview'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _StatisticCard(
              title: _text('Tổng bài tập', 'Total assignments'),
              value: _total.toString(),
              icon: Icons.assignment_rounded,
              color: const Color(0xFF4F46E5),
            ),
            _StatisticCard(
              title: _text('Đã hoàn thành', 'Completed'),
              value: _completed.toString(),
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF16A34A),
            ),
            _StatisticCard(
              title: _text('Chưa hoàn thành', 'Incomplete'),
              value: _incomplete.toString(),
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFF0891B2),
            ),
            _StatisticCard(
              title: _text('Đã quá hạn', 'Overdue'),
              value: _overdue.toString(),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEA580C),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final percentage = (_completionRate * 100).clamp(0.0, 100.0);

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
          Text(
            _text('Tỷ lệ hoàn thành', 'Completion rate'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  _text('đã hoàn thành', 'completed'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 11,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text(
              'Bạn đã hoàn thành $_completed trên $_total bài tập.',
              'You have completed $_completed out of $_total assignments.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    final completedRatio = _total == 0 ? 0.0 : _completed / _total;
    final incompleteRatio = _total == 0 ? 0.0 : _incomplete / _total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Phân bố trạng thái', 'Assignment status'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _buildStatusRow(
                theme: theme,
                title: _text('Đã hoàn thành', 'Completed'),
                count: _completed,
                ratio: completedRatio,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 20),
              _buildStatusRow(
                theme: theme,
                title: _text('Chưa hoàn thành', 'Incomplete'),
                count: _incomplete,
                ratio: incompleteRatio,
                color: const Color(0xFF0891B2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required ThemeData theme,
    required String title,
    required int count,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count (${(ratio * 100).toStringAsFixed(0)}%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 9,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueSection(ThemeData theme) {
    final hasOverdue = _overdue > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasOverdue
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: hasOverdue
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasOverdue
                      ? _text('Bài tập cần chú ý', 'Assignments need attention')
                      : _text('Tiến độ đúng hạn', 'On track'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasOverdue
                      ? _text(
                          'Bạn đang có $_overdue bài tập quá hạn chưa hoàn thành.',
                          'You have $_overdue overdue incomplete assignments.',
                        )
                      : _text(
                          'Hiện không có bài tập nào quá hạn.',
                          'There are currently no overdue assignments.',
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                'Không thể tải dữ liệu thống kê',
                'Unable to load statistics',
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
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Thử lại', 'Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
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
            ),
          ),
        ],
      ),
    );
  }
}

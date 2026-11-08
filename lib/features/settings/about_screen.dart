import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  String _text(BuildContext context, String vi, String en) {
    return Localizations.localeOf(context).languageCode == 'vi' ? vi : en;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(context, 'Thông tin dự án', 'Project information'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, const Color(0xFF7770EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Học Tốt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Study Planner',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 14),
                Text(
                  _text(
                    context,
                    'Đồng hành cùng bạn trên hành trình học tập.',
                    'Your companion on the learning journey.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          _sectionTitle(context, _text(context, 'Giới thiệu', 'Introduction')),
          const SizedBox(height: 12),
          _infoCard(
            context,
            icon: Icons.lightbulb_outline_rounded,
            title: _text(context, 'Mục đích', 'Purpose'),
            description: _text(
              context,
              'Học Tốt là ứng dụng hỗ trợ sinh viên quản lý môn học, '
                  'theo dõi bài tập, sắp xếp lịch học và theo dõi tiến độ '
                  'học tập trong một không gian thống nhất.',
              'Học Tốt helps students manage subjects, track assignments, '
                  'organize study schedules and monitor learning progress '
                  'in one place.',
            ),
          ),

          const SizedBox(height: 26),

          _sectionTitle(
            context,
            _text(context, 'Chức năng chính', 'Main features'),
          ),
          const SizedBox(height: 12),
          _infoCard(
            context,
            icon: Icons.menu_book_outlined,
            title: _text(context, 'Quản lý môn học', 'Subject management'),
            description: _text(
              context,
              'Thêm, chỉnh sửa, tìm kiếm và xóa thông tin môn học.',
              'Add, edit, search and delete subject information.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.assignment_outlined,
            title: _text(context, 'Quản lý bài tập', 'Assignment management'),
            description: _text(
              context,
              'Theo dõi hạn nộp, trạng thái hoàn thành, ghi chú và '
                  'tìm kiếm bài tập.',
              'Track deadlines, completion status, notes and search '
                  'assignments.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.calendar_month_outlined,
            title: _text(context, 'Quản lý lịch học', 'Study schedules'),
            description: _text(
              context,
              'Sắp xếp lịch học theo ngày và khung giờ.',
              'Organize study sessions by weekday and time.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.notifications_active_outlined,
            title: _text(context, 'Nhắc hạn bài tập', 'Deadline reminders'),
            description: _text(
              context,
              'Nhắc trước hạn nộp một ngày và một giờ.',
              'Send reminders one day and one hour before deadlines.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.bar_chart_rounded,
            title: _text(context, 'Thống kê học tập', 'Study statistics'),
            description: _text(
              context,
              'Tổng hợp số lượng bài tập, tiến độ hoàn thành và '
                  'các bài tập quá hạn.',
              'Summarize assignment counts, completion progress and '
                  'overdue assignments.',
            ),
          ),

          const SizedBox(height: 26),

          _sectionTitle(
            context,
            _text(context, 'Công nghệ sử dụng', 'Technologies'),
          ),
          const SizedBox(height: 12),
          _infoCard(
            context,
            icon: Icons.phone_android_rounded,
            title: 'Flutter & Dart',
            description: _text(
              context,
              'Phát triển giao diện và chức năng ứng dụng di động.',
              'Build the mobile application interface and features.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.storage_rounded,
            title: 'SQLite',
            description: _text(
              context,
              'Lưu trữ dữ liệu cục bộ ngay trên thiết bị.',
              'Store application data locally on the device.',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.translate_rounded,
            title: _text(context, 'Đa ngôn ngữ', 'Localization'),
            description: _text(
              context,
              'Hỗ trợ Tiếng Việt và Tiếng Anh.',
              'Supports Vietnamese and English.',
            ),
          ),

          const SizedBox(height: 26),

          _sectionTitle(
            context,
            _text(context, 'Thông tin học phần', 'Course information'),
          ),
          const SizedBox(height: 12),
          _infoCard(
            context,
            icon: Icons.account_balance_outlined,
            title: _text(
              context,
              'Trường Đại học Phenikaa',
              'Phenikaa University',
            ),
            description: _text(
              context,
              'Học phần: Lập trình thiết bị di động',
              'Course: Mobile Application Programming',
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            context,
            icon: Icons.person_outline_rounded,
            title: _text(context, 'Hình thức thực hiện', 'Project format'),
            description: _text(
              context,
              'Dự án hiện do một sinh viên thực hiện.',
              'Currently developed as an individual project.',
            ),
          ),

          const SizedBox(height: 26),

          Center(
            child: Column(
              children: [
                Text(
                  'Học Tốt • Study Planner',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '© 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/models/schedule.dart';
import '../../data/models/subject.dart';
import '../../data/services/schedule_service.dart';
import '../../data/services/subject_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final SubjectService _subjectService = SubjectService();

  List<Schedule> _schedules = [];
  List<Subject> _subjects = [];

  bool _isLoading = true;
  String? _errorMessage;

  int? _selectedWeekday;
  String? _selectedSubject;

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  static const List<int> _weekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _selectedWeekday = DateTime.now().weekday;
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _scheduleService.getAllSchedules(),
        _subjectService.getAllSubjects(),
      ]);

      final schedules = results[0] as List<Schedule>;
      final subjects = results[1] as List<Subject>;

      schedules.sort((a, b) {
        final weekdayCompare = a.weekday.compareTo(b.weekday);
        if (weekdayCompare != 0) return weekdayCompare;

        return _minutes(a.startTime).compareTo(_minutes(b.startTime));
      });

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _subjects = subjects;
        _isLoading = false;

        if (_selectedSubject != null &&
            !subjects.any((s) => s.subjectCode == _selectedSubject)) {
          _selectedSubject = null;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayName(int weekday) {
    const vi = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ nhật',
    ];

    const en = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return _isVietnamese ? vi[weekday] : en[weekday];
  }

  String _weekdayShort(int weekday) {
    const vi = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _isVietnamese ? vi[weekday] : en[weekday];
  }

  String _subjectName(String code) {
    final matches = _subjects.where((s) => s.subjectCode == code);
    return matches.isEmpty ? code : matches.first.name;
  }

  List<Schedule> get _filteredSchedules {
    return _schedules.where((schedule) {
      final matchesWeekday =
          _selectedWeekday == null || schedule.weekday == _selectedWeekday;

      final matchesSubject =
          _selectedSubject == null || schedule.subjectCode == _selectedSubject;

      return matchesWeekday && matchesSubject;
    }).toList()..sort(
      (a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _openScheduleForm({Schedule? schedule}) async {
    if (_subjects.isEmpty) {
      _showMessage(
        _text(
          'Bạn cần tạo môn học trước khi thêm lịch học.',
          'Create a subject before adding a schedule.',
        ),
        isError: true,
      );
      return;
    }

    String? subjectCode = schedule?.subjectCode ?? _subjects.first.subjectCode;
    int weekday = schedule?.weekday ?? DateTime.now().weekday;
    TimeOfDay startTime =
        schedule?.startTime ?? const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime =
        schedule?.endTime ?? const TimeOfDay(hour: 9, minute: 0);

    final locationController = TextEditingController(
      text: schedule?.location ?? '',
    );

    String? formError;
    bool isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? startTime : endTime,
                helpText: isStart
                    ? _text('Chọn giờ bắt đầu', 'Select start time')
                    : _text('Chọn giờ kết thúc', 'Select end time'),
              );

              if (picked == null) return;

              setDialogState(() {
                if (isStart) {
                  startTime = picked;
                } else {
                  endTime = picked;
                }
                formError = null;
              });
            }

            Future<void> save() async {
              if (_minutes(endTime) <= _minutes(startTime)) {
                setDialogState(() {
                  formError = _text(
                    'Giờ kết thúc phải sau giờ bắt đầu.',
                    'End time must be after start time.',
                  );
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                formError = null;
              });

              try {
                final newSchedule = Schedule(
                  id:
                      schedule?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  subjectCode: subjectCode!,
                  weekday: weekday,
                  startTime: startTime,
                  endTime: endTime,
                  location: locationController.text.trim().isEmpty
                      ? null
                      : locationController.text.trim(),
                );

                if (schedule == null) {
                  await _scheduleService.addSchedule(newSchedule);
                } else {
                  await _scheduleService.updateSchedule(newSchedule);
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (error) {
                setDialogState(() {
                  isSaving = false;
                  formError = _friendlyScheduleError(error);
                });
              }
            }

            return AlertDialog(
              title: Text(
                schedule == null
                    ? _text('Thêm lịch học', 'Add schedule')
                    : _text('Chỉnh sửa lịch học', 'Edit schedule'),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: subjectCode,
                        decoration: InputDecoration(
                          labelText: _text('Môn học *', 'Subject *'),
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject.subjectCode,
                            child: Text(
                              '${subject.subjectCode} - ${subject.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    subjectCode = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: weekday,
                        decoration: InputDecoration(
                          labelText: _text('Thứ trong tuần', 'Day of week'),
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        items: _weekdays.map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text(_weekdayName(day)),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() => weekday = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      _TimeSelectionTile(
                        title: _text('Giờ bắt đầu', 'Start time'),
                        time: _formatTime(startTime),
                        icon: Icons.play_circle_outline_rounded,
                        onTap: isSaving ? null : () => chooseTime(true),
                      ),
                      const SizedBox(height: 8),
                      _TimeSelectionTile(
                        title: _text('Giờ kết thúc', 'End time'),
                        time: _formatTime(endTime),
                        icon: Icons.stop_circle_outlined,
                        onTap: isSaving ? null : () => chooseTime(false),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: locationController,
                        enabled: !isSaving,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: _text(
                            'Địa điểm (không bắt buộc)',
                            'Location (optional)',
                          ),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          formError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(_text('Hủy', 'Cancel')),
                ),
                FilledButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_text('Lưu', 'Save')),
                ),
              ],
            );
          },
        );
      },
    );

    locationController.dispose();

    if (result == true && mounted) {
      await _loadData();
      _showMessage(
        schedule == null
            ? _text('Đã thêm lịch học.', 'Schedule added.')
            : _text('Đã cập nhật lịch học.', 'Schedule updated.'),
      );
    }
  }

  String _friendlyScheduleError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('overlap') ||
        message.contains('scheduleoverlap') ||
        message.contains('schedule_overlap')) {
      return _text(
        'Lịch học bị trùng với một buổi học khác.',
        'This schedule overlaps with another class.',
      );
    }

    if (message.contains('subjectnotfound') ||
        message.contains('subject_not_found')) {
      return _text(
        'Môn học không còn tồn tại. Vui lòng tải lại danh sách.',
        'The subject no longer exists. Please refresh the list.',
      );
    }

    return error.toString();
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text('Xóa lịch học?', 'Delete schedule?')),
        content: Text(
          _text(
            'Bạn có chắc muốn xóa lịch học môn ${_subjectName(schedule.subjectCode)} vào ${_weekdayName(schedule.weekday)} không?',
            'Delete the ${_subjectName(schedule.subjectCode)} class on ${_weekdayName(schedule.weekday)}?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_text('Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_text('Xóa', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _scheduleService.deleteSchedule(schedule.id);
      await _loadData();
      _showMessage(_text('Đã xóa lịch học.', 'Schedule deleted.'));
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredSchedules;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('Quản lý lịch học', 'Study schedule'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _text('Làm mới', 'Refresh'),
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_text('Thêm lịch học', 'Add schedule')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError(theme)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  _buildOverview(theme),
                  const SizedBox(height: 22),
                  Text(
                    _text('Chọn thứ', 'Choose a day'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeekdaySelector(theme),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String?>(
                    value: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: _text('Lọc theo môn học', 'Filter by subject'),
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(_text('Tất cả môn học', 'All subjects')),
                      ),
                      ..._subjects.map(
                        (subject) => DropdownMenuItem<String?>(
                          value: subject.subjectCode,
                          child: Text(
                            '${subject.subjectCode} - ${subject.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSubject = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedWeekday == null
                              ? _text('Toàn bộ lịch học', 'All schedules')
                              : _weekdayName(_selectedWeekday!),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${filtered.length} ${_text('buổi', 'classes')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    _buildEmptyState(theme)
                  else
                    ...filtered.map(
                      (schedule) => _buildScheduleCard(theme, schedule),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    final subjectCount = _subjects.length;
    final scheduleCount = _schedules.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF7770EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('Thời khóa biểu của bạn', 'Your study timetable'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(
                    '$scheduleCount buổi học • $subjectCount môn học',
                    '$scheduleCount classes • $subjectCount subjects',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector(ThemeData theme) {
    return Row(
      children: _weekdays.map((day) {
        final selected = _selectedWeekday == day;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedWeekday = selected ? null : day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekdayShort(day),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleCard(ThemeData theme, Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 82,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subjectName(schedule.subjectCode),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${schedule.subjectCode} • ${_weekdayName(schedule.weekday)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (schedule.location != null &&
                      schedule.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openScheduleForm(schedule: schedule);
                } else if (value == 'delete') {
                  _deleteSchedule(schedule);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(_text('Chỉnh sửa', 'Edit')),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(_text('Xóa', 'Delete')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 46,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _text('Chưa có lịch học', 'No schedules yet'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _text(
              'Thêm lịch học để xây dựng thời khóa biểu của bạn.',
              'Add classes to build your study timetable.',
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

  Widget _buildError(ThemeData theme) {
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
              _text('Không thể tải lịch học.', 'Unable to load schedules.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_text('Thử lại', 'Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelectionTile extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final VoidCallback? onTap;

  const _TimeSelectionTile({
    required this.title,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodySmall),
      subtitle: Text(
        time,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.access_time_rounded),
    );
  }
}

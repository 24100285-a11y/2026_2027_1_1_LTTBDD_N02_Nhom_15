import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/assignment.dart';
import '../../data/models/subject.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/subject_service.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final SubjectService _subjectService = SubjectService();
  final TextEditingController _searchController = TextEditingController();

  List<Assignment> _assignments = [];
  List<Subject> _subjects = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedSubject;
  AssignmentStatus? _selectedStatus;

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _assignmentService.getAllAssignments(),
        _subjectService.getAllSubjects(),
      ]);

      final assignments = results[0] as List<Assignment>;
      final subjects = results[1] as List<Subject>;

      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
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

  List<Assignment> get _filteredAssignments {
    final query = _searchQuery.trim().toLowerCase();

    return _assignments.where((assignment) {
      final matchesSearch =
          assignment.title.toLowerCase().contains(query) ||
          assignment.subjectCode.toLowerCase().contains(query);

      final matchesSubject =
          _selectedSubject == null ||
          assignment.subjectCode == _selectedSubject;

      final matchesStatus =
          _selectedStatus == null || assignment.status == _selectedStatus;

      return matchesSearch && matchesSubject && matchesStatus;
    }).toList();
  }

  int get _completedCount =>
      _assignments.where((a) => a.status == AssignmentStatus.completed).length;

  int get _incompleteCount => _assignments.length - _completedCount;

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _subjectName(String code) {
    final subject = _subjects.where((s) => s.subjectCode == code);
    return subject.isEmpty ? code : subject.first.name;
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

  Future<void> _openAssignmentForm({Assignment? assignment}) async {
    if (_subjects.isEmpty) {
      _showMessage(
        _text(
          'Bạn cần tạo môn học trước khi thêm bài tập.',
          'Create a subject before adding an assignment.',
        ),
        isError: true,
      );
      return;
    }

    final titleController = TextEditingController(
      text: assignment?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: assignment?.description ?? '',
    );

    String? subjectCode =
        assignment?.subjectCode ?? _subjects.first.subjectCode;
    DateTime assignedDate = assignment?.assignedDate ?? DateTime.now();
    DateTime deadline =
        assignment?.deadline ?? DateTime.now().add(const Duration(days: 7));

    String? formError;
    bool isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseDate(bool isDeadline) async {
              final initialDate = isDeadline ? deadline : assignedDate;

              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                helpText: isDeadline
                    ? _text('Chọn hạn nộp', 'Select deadline')
                    : _text('Chọn ngày giao', 'Select assigned date'),
              );

              if (picked == null) return;

              setDialogState(() {
                final selected = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                );

                if (isDeadline) {
                  deadline = selected;
                } else {
                  assignedDate = selected;
                }

                formError = null;
              });
            }

            Future<void> save() async {
              if (titleController.text.trim().isEmpty) {
                setDialogState(() {
                  formError = _text(
                    'Vui lòng nhập tên bài tập.',
                    'Please enter an assignment title.',
                  );
                });
                return;
              }

              if (deadline.isBefore(
                DateTime(
                  assignedDate.year,
                  assignedDate.month,
                  assignedDate.day,
                ),
              )) {
                setDialogState(() {
                  formError = _text(
                    'Hạn nộp không được trước ngày giao bài.',
                    'Deadline cannot be before the assigned date.',
                  );
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                formError = null;
              });

              try {
                final newAssignment = Assignment(
                  id:
                      assignment?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  subjectCode: subjectCode!,
                  assignedDate: assignedDate,
                  deadline: deadline,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  note: assignment?.note,
                  status: assignment?.status ?? AssignmentStatus.incomplete,
                );

                if (assignment == null) {
                  await _assignmentService.addAssignment(newAssignment);
                } else {
                  await _assignmentService.updateAssignment(newAssignment);
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (error) {
                setDialogState(() {
                  isSaving = false;
                  formError = error.toString();
                });
              }
            }

            return AlertDialog(
              title: Text(
                assignment == null
                    ? _text('Thêm bài tập', 'Add assignment')
                    : _text('Chỉnh sửa bài tập', 'Edit assignment'),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: _text('Tên bài tập *', 'Title *'),
                          prefixIcon: const Icon(Icons.assignment_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                      TextField(
                        controller: descriptionController,
                        enabled: !isSaving,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _text(
                            'Mô tả (không bắt buộc)',
                            'Description (optional)',
                          ),
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DateSelectionTile(
                        title: _text('Ngày giao bài', 'Assigned date'),
                        date: _formatDate(assignedDate),
                        onTap: isSaving ? null : () => chooseDate(false),
                      ),
                      const SizedBox(height: 8),
                      _DateSelectionTile(
                        title: _text('Hạn nộp', 'Deadline'),
                        date: _formatDate(deadline),
                        onTap: isSaving ? null : () => chooseDate(true),
                        color: Theme.of(context).colorScheme.error,
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

    titleController.dispose();
    descriptionController.dispose();

    if (result == true && mounted) {
      await _loadData();
      _showMessage(
        assignment == null
            ? _text('Đã thêm bài tập.', 'Assignment added.')
            : _text('Đã cập nhật bài tập.', 'Assignment updated.'),
      );
    }
  }

  Future<void> _changeStatus(Assignment assignment) async {
    final newStatus = assignment.status == AssignmentStatus.completed
        ? AssignmentStatus.incomplete
        : AssignmentStatus.completed;

    try {
      await _assignmentService.updateStatus(assignment.id, newStatus);
      await _loadData();

      _showMessage(
        newStatus == AssignmentStatus.completed
            ? _text('Đã hoàn thành bài tập.', 'Assignment completed.')
            : _text('Đã chuyển về chưa hoàn thành.', 'Marked as incomplete.'),
      );
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _editNote(Assignment assignment) async {
    final controller = TextEditingController(text: assignment.note ?? '');

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('Ghi chú bài tập', 'Assignment notes')),
          content: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _text('Nhập ghi chú của bạn...', 'Enter your notes...'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_text('Hủy', 'Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(_text('Lưu ghi chú', 'Save note')),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    try {
      await _assignmentService.updateNote(
        assignment.id,
        result.isEmpty ? null : result,
      );
      await _loadData();
      _showMessage(_text('Đã lưu ghi chú.', 'Note saved.'));
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text('Xóa bài tập?', 'Delete assignment?')),
        content: Text(
          _text(
            'Bạn có chắc muốn xóa "${assignment.title}" không?',
            'Are you sure you want to delete "${assignment.title}"?',
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
      await _assignmentService.deleteAssignment(assignment.id);
      await _loadData();
      _showMessage(_text('Đã xóa bài tập.', 'Assignment deleted.'));
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredAssignments;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('Quản lý bài tập', 'Assignments'),
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
        onPressed: () => _openAssignmentForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_text('Thêm bài tập', 'Add assignment')),
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
                  _buildSummary(theme),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: _text(
                        'Tìm tên bài tập hoặc mã môn học...',
                        'Search assignments or subject codes...',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(theme),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _text('Danh sách bài tập', 'Assignment list'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${filtered.length}',
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
                      (assignment) => _buildAssignmentCard(theme, assignment),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: _text('Tổng bài tập', 'Total'),
            value: _assignments.length.toString(),
            icon: Icons.assignment_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: _text('Hoàn thành', 'Completed'),
            value: _completedCount.toString(),
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: _text('Còn lại', 'Incomplete'),
            value: _incompleteCount.toString(),
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          value: _selectedSubject,
          decoration: InputDecoration(
            labelText: _text('Lọc theo môn học', 'Filter by subject'),
            prefixIcon: const Icon(Icons.menu_book_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
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
          onChanged: (value) => setState(() => _selectedSubject = value),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: _text('Tất cả', 'All'),
                selected: _selectedStatus == null,
                onSelected: () => setState(() => _selectedStatus = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _text('Chưa hoàn thành', 'Incomplete'),
                selected: _selectedStatus == AssignmentStatus.incomplete,
                onSelected: () => setState(
                  () => _selectedStatus = AssignmentStatus.incomplete,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _text('Đã hoàn thành', 'Completed'),
                selected: _selectedStatus == AssignmentStatus.completed,
                onSelected: () => setState(
                  () => _selectedStatus = AssignmentStatus.completed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(ThemeData theme, Assignment assignment) {
    final isCompleted = assignment.status == AssignmentStatus.completed;
    final isOverdue = assignment.isOverdueAt(DateTime.now());

    final statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : isOverdue
        ? theme.colorScheme.error
        : const Color(0xFFEA580C);

    final statusText = isCompleted
        ? _text('Đã hoàn thành', 'Completed')
        : isOverdue
        ? _text('Quá hạn', 'Overdue')
        : _text('Chưa hoàn thành', 'Incomplete');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.task_alt_rounded
                        : Icons.assignment_outlined,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${assignment.subjectCode} • ${_subjectName(assignment.subjectCode)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openAssignmentForm(assignment: assignment);
                        break;
                      case 'note':
                        _editNote(assignment);
                        break;
                      case 'delete':
                        _deleteAssignment(assignment);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(_text('Chỉnh sửa', 'Edit')),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'note',
                      child: ListTile(
                        leading: const Icon(Icons.notes_rounded),
                        title: Text(_text('Ghi chú', 'Notes')),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: Text(_text('Xóa', 'Delete')),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (assignment.description != null &&
                assignment.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                assignment.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 17,
                  color: isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_text('Hạn nộp:', 'Deadline:')} ${_formatDate(assignment.deadline)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changeStatus(assignment),
                icon: Icon(
                  isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  isCompleted
                      ? _text('Đánh dấu chưa hoàn thành', 'Mark incomplete')
                      : _text('Đánh dấu hoàn thành', 'Mark completed'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilter =
        _searchQuery.isNotEmpty ||
        _selectedSubject != null ||
        _selectedStatus != null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.assignment_add,
            size: 45,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? _text(
                    'Không tìm thấy bài tập phù hợp.',
                    'No matching assignments.',
                  )
                : _text('Chưa có bài tập nào.', 'No assignments yet.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? _text(
                    'Thử thay đổi từ khóa hoặc bộ lọc.',
                    'Try changing your search or filters.',
                  )
                : _text(
                    'Thêm bài tập đầu tiên để bắt đầu nhé.',
                    'Add your first assignment to get started.',
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
              _text(
                'Không thể tải danh sách bài tập.',
                'Unable to load assignments.',
              ),
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

class _DateSelectionTile extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback? onTap;
  final Color? color;

  const _DateSelectionTile({
    required this.title,
    required this.date,
    required this.onTap,
    this.color,
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
      leading: Icon(Icons.calendar_month_rounded, color: color),
      title: Text(title, style: theme.textTheme.bodySmall),
      subtitle: Text(
        date,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.edit_calendar_rounded),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

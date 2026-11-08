import 'package:flutter/material.dart';

import '../../data/models/subject.dart';
import '../../data/services/subject_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectService _subjectService = SubjectService();
  final TextEditingController _searchController = TextEditingController();

  List<Subject> _subjects = [];
  bool _isLoading = true;
  String _searchKeyword = '';

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  final List<String> _colors = [
    '#4F46E5',
    '#0EA5E9',
    '#16A34A',
    '#F59E0B',
    '#EC4899',
    '#8B5CF6',
    '#EF4444',
    '#14B8A6',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final result = _searchKeyword.trim().isEmpty
          ? await _subjectService.getAllSubjects()
          : await _subjectService.searchSubjects(_searchKeyword);

      if (!mounted) return;

      setState(() {
        _subjects = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        _text('Không thể tải danh sách môn học.', 'Unable to load subjects.'),
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Color _parseColor(String? hex) {
    try {
      final value = (hex ?? '#4F46E5').replaceAll('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  Future<void> _openSubjectForm({Subject? subject}) async {
    final codeController = TextEditingController(
      text: subject?.subjectCode ?? '',
    );
    final nameController = TextEditingController(text: subject?.name ?? '');
    final lecturerController = TextEditingController(
      text: subject?.lecturer ?? '',
    );
    final descriptionController = TextEditingController(
      text: subject?.description ?? '',
    );

    String selectedColor = subject?.color ?? _colors.first;

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                subject == null
                    ? _text('Thêm môn học', 'Add Subject')
                    : _text('Chỉnh sửa môn học', 'Edit Subject'),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: codeController,
                          enabled: subject == null,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: _text('Mã môn học *', 'Subject Code *'),
                            prefixIcon: const Icon(Icons.tag_rounded),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _text(
                                'Vui lòng nhập mã môn học.',
                                'Please enter a subject code.',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: _text('Tên môn học *', 'Subject Name *'),
                            prefixIcon: const Icon(Icons.menu_book_rounded),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _text(
                                'Vui lòng nhập tên môn học.',
                                'Please enter a subject name.',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: lecturerController,
                          decoration: InputDecoration(
                            labelText: _text('Giảng viên', 'Lecturer'),
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: _text(
                              'Mô tả môn học',
                              'Subject Description',
                            ),
                            prefixIcon: const Icon(Icons.notes_rounded),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _text('Màu đại diện', 'Subject Color'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colors.map((hex) {
                            final color = _parseColor(hex);
                            final selected = selectedColor == hex;

                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = hex;
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 21,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(_text('Hủy', 'Cancel')),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final newSubject = Subject(
                              subjectCode: codeController.text.trim(),
                              name: nameController.text.trim(),
                              lecturer: lecturerController.text.trim().isEmpty
                                  ? null
                                  : lecturerController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              color: selectedColor,
                            );

                            if (subject == null) {
                              await _subjectService.addSubject(newSubject);
                            } else {
                              await _subjectService.updateSubject(newSubject);
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);
                            await _loadSubjects();

                            _showMessage(
                              subject == null
                                  ? _text(
                                      'Đã thêm môn học thành công.',
                                      'Subject added successfully.',
                                    )
                                  : _text(
                                      'Đã cập nhật môn học.',
                                      'Subject updated successfully.',
                                    ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            final message = e.toString();

                            String displayMessage;

                            if (message.contains('duplicateSubjectCode')) {
                              displayMessage = _text(
                                'Mã môn học đã tồn tại.',
                                'Subject code already exists.',
                              );
                            } else if (message.contains('emptyName')) {
                              displayMessage = _text(
                                'Tên môn học không được để trống.',
                                'Subject name cannot be empty.',
                              );
                            } else {
                              displayMessage = _text(
                                'Không thể lưu môn học. Vui lòng kiểm tra lại thông tin.',
                                'Unable to save subject. Please check the information.',
                              );
                            }

                            _showMessage(displayMessage, isError: true);
                          }
                        },
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

    codeController.dispose();
    nameController.dispose();
    lecturerController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_text('Xóa môn học?', 'Delete Subject?')),
          content: Text(
            _text(
              'Bạn có chắc chắn muốn xóa môn học "${subject.name}" không? '
                  'Thao tác này không thể hoàn tác.',
              'Are you sure you want to delete "${subject.name}"? '
                  'This action cannot be undone.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_text('Hủy', 'Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(_text('Xóa', 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _subjectService.deleteSubject(subject.subjectCode);
      await _loadSubjects();

      _showMessage(_text('Đã xóa môn học.', 'Subject deleted successfully.'));
    } catch (e) {
      final message = e.toString();

      if (message.contains('subjectHasDependencies')) {
        _showMessage(
          _text(
            'Không thể xóa môn học này vì đang có bài tập hoặc lịch học liên kết.',
            'Cannot delete this subject because assignments or schedules are linked to it.',
          ),
          isError: true,
        );
      } else {
        _showMessage(
          _text('Không thể xóa môn học.', 'Unable to delete subject.'),
          isError: true,
        );
      }
    }
  }

  Widget _buildSubjectCard(Subject subject) {
    final color = _parseColor(subject.color);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.menu_book_rounded, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subject.subjectCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subject.lecturer != null &&
                      subject.lecturer!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      subject.lecturer!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: _text('Tùy chọn', 'Options'),
              onSelected: (value) {
                if (value == 'edit') {
                  _openSubjectForm(subject: subject);
                } else if (value == 'delete') {
                  _deleteSubject(subject);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(_text('Chỉnh sửa', 'Edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _text('Xóa môn học', 'Delete Subject'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 55),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _text('Chưa có môn học nào', 'No subjects yet'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _text(
                'Hãy thêm môn học đầu tiên của bạn.',
                'Add your first subject to get started.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('Môn học', 'Subjects'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _text('Làm mới', 'Refresh'),
            onPressed: _loadSubjects,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubjectForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_text('Thêm môn học', 'Add Subject')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchKeyword = value;
                _loadSubjects();
              },
              decoration: InputDecoration(
                hintText: _text(
                  'Tìm theo tên hoặc mã môn học...',
                  'Search by subject name or code...',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchKeyword = '';
                          _loadSubjects();
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subjects.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadSubjects,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        return _buildSubjectCard(_subjects[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

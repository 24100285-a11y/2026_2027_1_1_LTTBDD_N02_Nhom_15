import 'package:flutter/foundation.dart';

import '../../core/validators/assignment_validator.dart';
import '../models/assignment.dart';
import '../models/app_settings.dart';
import '../repositories/assignment_repository.dart';
import '../repositories/subject_repository.dart';
import 'assignment_reminder_manager.dart';
import 'settings_service.dart';

class AssignmentService {
  final AssignmentRepository _assignmentRepository;
  final SubjectRepository _subjectRepository;
  final AssignmentReminderManager _reminderManager;
  final SettingsService _settingsService;

  AssignmentService({
    AssignmentRepository? assignmentRepository,
    SubjectRepository? subjectRepository,
    AssignmentReminderManager? reminderManager,
    SettingsService? settingsService,
  }) : _assignmentRepository = assignmentRepository ?? AssignmentRepository(),
       _subjectRepository = subjectRepository ?? SubjectRepository(),
       _reminderManager = reminderManager ?? AssignmentReminderManager(),
       _settingsService = settingsService ?? SettingsService();

  // Lấy ngôn ngữ hiện tại của ứng dụng.
  Future<bool> _getIsVietnamese() async {
    final language = await _settingsService.getLanguage();
    return language == AppLanguage.vi;
  }

  // Đồng bộ thông báo của một bài tập.
  Future<void> _syncReminders(Assignment assignment) async {
    try {
      final isVietnamese = await _getIsVietnamese();

      await _reminderManager.syncAssignmentReminders(
        assignment,
        isVietnamese: isVietnamese,
      );
    } catch (error) {
      // Không để lỗi thông báo làm mất thao tác lưu bài tập.
      debugPrint(
        'Reminder synchronization failed '
        'for assignment ${assignment.id}: $error',
      );
    }
  }

  // Lấy danh sách bài tập.
  Future<List<Assignment>> getAllAssignments() {
    return _assignmentRepository.getAllAssignments();
  }

  // Lấy bài tập theo ID.
  Future<Assignment?> getAssignmentById(String id) {
    return _assignmentRepository.getAssignmentById(id);
  }

  // Lấy bài tập theo môn học.
  Future<List<Assignment>> getAssignmentsBySubject(String subjectCode) {
    return _assignmentRepository.getAssignmentsBySubject(subjectCode);
  }

  // Lấy bài tập theo trạng thái.
  Future<List<Assignment>> getAssignmentsByStatus(AssignmentStatus status) {
    return _assignmentRepository.getAssignmentsByStatus(status);
  }

  // Tìm kiếm và lọc bài tập.
  Future<List<Assignment>> searchAssignments(
    String keyword, {
    AssignmentStatus? status,
    String? subjectCode,
  }) {
    return _assignmentRepository.searchAssignments(
      keyword,
      status: status,
      subjectCode: subjectCode,
    );
  }

  // Lấy bài tập quá hạn.
  Future<List<Assignment>> getOverdueAssignments({DateTime? now}) {
    return _assignmentRepository.getOverdueAssignments(now: now);
  }

  // Lấy bài tập sắp đến hạn.
  Future<List<Assignment>> getUpcomingAssignments({DateTime? now}) {
    return _assignmentRepository.getUpcomingAssignments(now: now);
  }

  // Kiểm tra dữ liệu bài tập.
  Future<void> _validateAssignment(Assignment assignment) async {
    final subjects = await _subjectRepository.getAllSubjects();

    final validationError = AssignmentValidator.validate(
      title: assignment.title,
      subjectCode: assignment.subjectCode,
      assignedDate: assignment.assignedDate,
      deadline: assignment.deadline,
      existingSubjects: subjects,
    );

    if (validationError != null) {
      throw Exception(validationError.name);
    }
  }

  // Thêm bài tập và tạo lịch nhắc hạn.
  Future<void> addAssignment(Assignment assignment) async {
    await _validateAssignment(assignment);

    await _assignmentRepository.insertAssignment(assignment);

    await _syncReminders(assignment);
  }

  // Cập nhật bài tập và đồng bộ lại lịch nhắc.
  Future<void> updateAssignment(Assignment assignment) async {
    await _validateAssignment(assignment);

    final existing = await _assignmentRepository.getAssignmentById(
      assignment.id,
    );

    if (existing == null) {
      throw Exception('assignmentNotFound');
    }

    await _assignmentRepository.updateAssignment(assignment);

    await _syncReminders(assignment);
  }

  // Cập nhật trạng thái bài tập.
  Future<void> updateStatus(String id, AssignmentStatus status) async {
    final existing = await _assignmentRepository.getAssignmentById(id);

    if (existing == null) {
      throw Exception('assignmentNotFound');
    }

    await _assignmentRepository.updateAssignmentStatus(id, status);

    final updated = await _assignmentRepository.getAssignmentById(id);

    if (updated != null) {
      await _syncReminders(updated);
    }
  }

  // Cập nhật ghi chú.
  Future<void> updateNote(String id, String? note) async {
    final existing = await _assignmentRepository.getAssignmentById(id);

    if (existing == null) {
      throw Exception('assignmentNotFound');
    }

    await _assignmentRepository.updateAssignmentNote(id, note);
  }

  // Xóa bài tập và các lịch nhắc liên quan.
  Future<void> deleteAssignment(String id) async {
    final existing = await _assignmentRepository.getAssignmentById(id);

    if (existing == null) {
      throw Exception('assignmentNotFound');
    }

    try {
      await _reminderManager.cancelAssignmentReminders(id);
    } catch (error) {
      debugPrint('Could not cancel reminders for assignment $id: $error');
    }

    await _assignmentRepository.deleteAssignment(id);
  }

  // Thống kê bài tập.
  Future<int> getTotalCount() {
    return _assignmentRepository.getAssignmentCount();
  }

  Future<int> getCompletedCount() {
    return _assignmentRepository.getCompletedAssignmentCount();
  }

  Future<int> getIncompleteCount() {
    return _assignmentRepository.getIncompleteAssignmentCount();
  }

  Future<double> getCompletionRate() {
    return _assignmentRepository.getCompletionRate();
  }

  // Các hàm thống kê tương thích với những màn hình hiện tại.
  Future<int> getAssignmentCount() {
    return _assignmentRepository.getAssignmentCount();
  }

  Future<int> getCompletedAssignmentCount() {
    return _assignmentRepository.getCompletedAssignmentCount();
  }

  Future<int> getIncompleteAssignmentCount() {
    return _assignmentRepository.getIncompleteAssignmentCount();
  }
}

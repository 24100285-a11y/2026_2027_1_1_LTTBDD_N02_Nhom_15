import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String subjectCode;
  final int weekday;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? location;

  const Schedule({
    required this.id,
    required this.subjectCode,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.location,
  });
}

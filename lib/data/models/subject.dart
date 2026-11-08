class Subject {
  final String subjectCode;
  final String name;
  final String? lecturer;
  final String? description;
  final String color;

  const Subject({
    required this.subjectCode,
    required this.name,
    this.lecturer,
    this.description,
    required this.color,
  });

  Subject copyWith({
    String? subjectCode,
    String? name,
    String? lecturer,
    String? description,
    String? color,
  }) {
    return Subject(
      subjectCode: subjectCode ?? this.subjectCode,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }
}

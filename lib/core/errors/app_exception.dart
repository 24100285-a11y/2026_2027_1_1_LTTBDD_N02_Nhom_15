class AppException implements Exception {
  final String code;

  const AppException(this.code);

  @override
  String toString() => code;
}

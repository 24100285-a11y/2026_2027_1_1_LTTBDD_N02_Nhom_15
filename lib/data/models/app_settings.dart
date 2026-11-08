enum AppLanguage { vi, en }

class AppSettings {
  final AppLanguage language;

  const AppSettings({required this.language});

  AppSettings copyWith({AppLanguage? language}) {
    return AppSettings(language: language ?? this.language);
  }
}

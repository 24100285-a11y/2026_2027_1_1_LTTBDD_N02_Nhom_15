import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

class SettingsService {
  final SettingsRepository _repository;

  SettingsService({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository();

  Future<AppSettings> getSettings() {
    return _repository.getSettings();
  }

  Future<AppLanguage> getLanguage() {
    return _repository.getLanguage();
  }

  Future<void> changeLanguage(AppLanguage language) {
    return _repository.updateLanguage(language);
  }
}

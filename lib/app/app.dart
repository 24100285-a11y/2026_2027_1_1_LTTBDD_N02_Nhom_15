import 'package:flutter/material.dart';

import 'app_settings_controller.dart';
import 'theme.dart';

import '../core/localization/generated/app_localizations.dart';
import '../features/dashboard/dashboard_screen.dart';

class HocTotApp extends StatefulWidget {
  const HocTotApp({super.key});

  @override
  State<HocTotApp> createState() => _HocTotAppState();
}

class _HocTotAppState extends State<HocTotApp> {
  late final AppSettingsController _settingsController;

  @override
  void initState() {
    super.initState();

    _settingsController = AppSettingsController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await _settingsController.loadSettings();
    } catch (error) {
      debugPrint('Could not load app settings: $error');
    }
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, child) {
        return AppSettingsScope(
          controller: _settingsController,
          child: MaterialApp(
            title: 'Học Tốt',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: _settingsController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const DashboardScreen(),
          ),
        );
      },
    );
  }
}

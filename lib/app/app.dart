import 'package:flutter/material.dart';

import 'app_settings_controller.dart';
import 'theme.dart';

import '../core/localization/generated/app_localizations.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/assignments/assignments_screen.dart';
import '../features/schedules/schedules_screen.dart';
import '../features/statistics/statistics_screen.dart';

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
            home: const MainNavigationScreen(),
          ),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  bool get _isVietnamese =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _text(String vi, String en) => _isVietnamese ? vi : en;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const SubjectsScreen(),
    const AssignmentsScreen(),
    const SchedulesScreen(),
    const StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: _text('Tổng quan', 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: _text('Môn học', 'Subjects'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment_rounded),
            label: _text('Bài tập', 'Assignments'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: _text('Lịch học', 'Schedules'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: _text('Thống kê', 'Statistics'),
          ),
        ],
      ),
    );
  }
}

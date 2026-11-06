import 'package:flutter/material.dart';

import 'theme.dart';
import '../core/localization/generated/app_localizations.dart';
import '../features/dashboard/dashboard_screen.dart';

class HocTotApp extends StatelessWidget {
  const HocTotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Học Tốt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Ngôn ngữ mặc định
      locale: const Locale('vi'),

      // Các ngôn ngữ được hỗ trợ
      supportedLocales: AppLocalizations.supportedLocales,

      // Bộ dịch của ứng dụng
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      home: const DashboardScreen(),
    );
  }
}

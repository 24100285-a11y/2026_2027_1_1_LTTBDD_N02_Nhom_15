import 'package:flutter/material.dart';

import 'theme.dart';
import '../features/dashboard/dashboard_screen.dart';

class HocTotApp extends StatelessWidget {
  const HocTotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Học Tốt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}

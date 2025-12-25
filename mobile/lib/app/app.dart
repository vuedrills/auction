import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/services/notification_manager.dart';

/// Main AirMass App widget
class AirMassApp extends ConsumerWidget {
  const AirMassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return NotificationManager(
      child: MaterialApp.router(
        title: 'AirMass',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}

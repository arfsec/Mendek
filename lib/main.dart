import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/schedule.dart';
import 'services/db_service.dart';
import 'services/notif_service.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SQLite Database
  await DbService.instance.database;

  // 2. Initialize Notifications & Timezones
  await NotifService.instance.init(rootNavigatorKey);

  // 3. Reschedule active alarms on startup to ensure precision
  try {
    final List<Schedule> allSchedules =
        await DbService.instance.getAllSchedules();
    await NotifService.instance.rescheduleAll(allSchedules);
  } catch (e) {
    debugPrint('Startup reschedule error: $e');
  }

  runApp(const MendekArenaApp());
}

class MendekArenaApp extends StatefulWidget {
  const MendekArenaApp({super.key});

  @override
  State<MendekArenaApp> createState() => _MendekArenaAppState();
}

class _MendekArenaAppState extends State<MendekArenaApp> {
  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();

    // Check if launched directly from a notification click
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotifService.instance.checkAppLaunchNotification();
    });
  }

  Future<void> _requestInitialPermissions() async {
    // 1. Notification Permission (Android 13+)
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+)
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('Schedule exact alarm permission check skipped: $e');
    }

    // 3. Ignore Battery Optimization (Critical for reliable schedule alarm)
    try {
      final batteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Ignore battery optimization permission check skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1B5E20); // Colors.green.shade800

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Mendek Arena Masteran Burung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          primary: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 1.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}
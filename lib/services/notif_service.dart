import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/schedule.dart';
import '../screens/player_screen.dart';

class NotifService {
  static final NotifService instance = NotifService._internal();
  NotifService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'masteran_alarm_channel_high';
  static const String channelName = 'Jadwal Masteran Burung';
  static const String channelDescription =
      'Alarm otomatis layar penuh untuk memutar video masteran burung';

  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationPayload(payload);
        }
      },
    );

    if (Platform.isAndroid) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> checkAppLaunchNotification() async {
    final NotificationAppLaunchDetails? details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleNotificationPayload(payload);
        });
      }
    }
  }

  void _handleNotificationPayload(String payload) {
    final parts = payload.split('|');
    if (parts.length >= 3) {
      final scheduleId = parts[0];
      final url = parts[1];
      final timeParts = parts[2].split(':');
      final endHour = int.tryParse(timeParts[0]) ?? 7;
      final endMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final name = parts.length >= 4 ? parts[3] : 'Masteran Burung';

      navigatorKey?.currentState?.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            scheduleId: scheduleId,
            scheduleTitle: name,
            rawUrl: url,
            endHour: endHour,
            endMinute: endMinute,
          ),
        ),
      );
    }
  }

  Future<void> scheduleAlarm(Schedule schedule) async {
    if (!schedule.isActive || schedule.daysOfWeek.isEmpty) {
      await cancelSchedule(schedule);
      return;
    }

    await cancelSchedule(schedule);

    final payload =
        '${schedule.id}|${schedule.url}|${schedule.endHour}:${schedule.endMinute}|${schedule.name}';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'Masteran Kicau Mulai: ${schedule.name}',
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    for (final day in schedule.daysOfWeek) {
      final notifId = _generateNotificationId(schedule.id, day);
      final scheduledDate = _nextInstanceOfDayAndTime(
        day,
        schedule.startHour,
        schedule.startMinute,
      );

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notifId,
          'Waktunya Masteran: ${schedule.name}',
          'Memutar masteran sampai ${schedule.formattedEndTime}. Ketuk untuk layar penuh.',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Error scheduling exact alarm for ${schedule.name}: $e');
      }
    }
  }

  Future<void> cancelSchedule(Schedule schedule) async {
    for (int day = 1; day <= 7; day++) {
      final notifId = _generateNotificationId(schedule.id, day);
      await flutterLocalNotificationsPlugin.cancel(notifId);
    }
  }

  Future<void> rescheduleAll(List<Schedule> schedules) async {
    for (final schedule in schedules) {
      if (schedule.isActive) {
        await scheduleAlarm(schedule);
      } else {
        await cancelSchedule(schedule);
      }
    }
  }

  int _generateNotificationId(String scheduleId, int day) {
    final hash = scheduleId.hashCode & 0x7FFFFFFF;
    return (hash % 100000) * 10 + day;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
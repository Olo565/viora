import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../utils/calculator.dart';

/// Mengatur notifikasi lokal harian untuk pengingat makan & minum air.
///
/// PENTING: notifikasi lokal (flutter_local_notifications) hanya berjalan
/// stabil di build Android & iOS (aplikasi asli). Saat dijalankan lewat
/// `flutter run -d chrome` (browser), notifikasi TIDAK akan muncul karena
/// browser tidak mengizinkan background scheduling seperti aplikasi native.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // fallback diam-diam kalau lokasi timezone tidak ditemukan
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Minta izin notifikasi ke user (wajib di Android 13+ dan iOS).
  Future<bool> requestPermission() async {
    await init();
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? true;
    }
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    }
    return granted;
  }

  Future<void> _scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vitafit_meal_channel',
          'Pengingat Makan & Minum',
          channelDescription: 'Notifikasi jadwal makan dan minum air harian Viora',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // biar notifikasinya otomatis berulang tiap hari di jam yang sama
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Jadwalkan seluruh timeline (makan + minum) satu hari, berulang tiap hari.
  Future<void> scheduleDailySchedule(List<ScheduleItem> schedule) async {
    await init();
    await cancelAll();
    for (var i = 0; i < schedule.length; i++) {
      final item = schedule[i];
      String title;
      switch (item.type) {
        case ScheduleType.hydration:
          title = 'Waktunya Minum Air';
          break;
        case ScheduleType.exercise:
          title = 'Waktunya Olahraga: ${item.title}';
          break;
        case ScheduleType.meal:
          title = 'Waktunya ${item.title}';
          break;
      }
      await _scheduleDaily(
        id: i,
        time: item.time,
        title: title,
        body: item.description,
      );
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

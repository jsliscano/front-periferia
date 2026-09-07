import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/tasks/domain/entities/task.dart';

class TaskNotificationService {
  TaskNotificationService._();

  static final TaskNotificationService instance = TaskNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;

  static const int upcomingDays = 1;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    if (_initialized) return;

    tz.setLocalLocation(
      tz.Location(
        'America/Bogota',
        [tz.minTime],
        const [0],
        const [
          tz.TimeZone(
            Duration(hours: -5),
            isDst: false,
            abbreviation: 'COT',
          ),
        ],
      ),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Prueba Periferia',
      appUserModelId: 'com.example.prueba_periferia',
      guid: 'd4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f70',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(settings: settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  List<Task> getUpcomingTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: upcomingDays));

    return tasks.where((task) {
      if (task.isCompletada || task.fechaVencimiento == null) return false;
      final due = DateTime(
        task.fechaVencimiento!.year,
        task.fechaVencimiento!.month,
        task.fechaVencimiento!.day,
      );
      return !due.isAfter(limit);
    }).toList()
      ..sort((a, b) {
        final aDate = a.fechaVencimiento!;
        final bDate = b.fechaVencimiento!;
        return aDate.compareTo(bDate);
      });
  }

  Future<void> syncFromTasks(List<Task> tasks) async {
    try {
      if (!_initialized) await init();
      await _plugin.cancelAll();

      final pending = tasks.where(
        (task) => !task.isCompletada && task.fechaVencimiento != null,
      );

      for (final task in pending) {
        await _scheduleForTask(task);
      }
    } catch (_) {
    }
  }

  Future<void> cancelForTask(int taskId) async {
    try {
      if (!_initialized) return;
      await _plugin.cancel(id: _notificationId(taskId, 0));
      await _plugin.cancel(id: _notificationId(taskId, 1));
    } catch (_) {}
  }

  Future<void> _scheduleForTask(Task task) async {
    final due = task.fechaVencimiento;
    if (due == null) return;

    final dueDay = DateTime(due.year, due.month, due.day, 9);
    final reminderDay = dueDay.subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);

    final reminderTz = tz.TZDateTime(
      tz.local,
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      9,
    );
    if (reminderTz.isAfter(now)) {
      await _zonedSchedule(
        id: _notificationId(task.id, 0),
        title: 'Tarea próxima a vencer',
        body:
            '"${task.titulo}" vence mañana (${_formatDate(due)}).',
        when: reminderTz,
      );
    }

    final dueTz = tz.TZDateTime(
      tz.local,
      dueDay.year,
      dueDay.month,
      dueDay.day,
      9,
    );
    if (dueTz.isAfter(now)) {
      await _zonedSchedule(
        id: _notificationId(task.id, 1),
        title: 'Tarea vence hoy',
        body: '"${task.titulo}" vence hoy.',
        when: dueTz,
      );
    } else if (_isDueSoon(due)) {
      await _plugin.show(
        id: _notificationId(task.id, 1),
        title: _isOverdue(due) ? 'Tarea vencida' : 'Tarea próxima a vencer',
        body:
            '"${task.titulo}" ${_isOverdue(due) ? 'ya venció' : 'vence pronto'} (${_formatDate(due)}).',
        notificationDetails: _details(),
      );
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tasks_due_channel',
        'Tareas por vencer',
        channelDescription:
            'Recordatorios de tareas próximas a su fecha de vencimiento',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );
  }

  bool _isDueSoon(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    return diff <= upcomingDays;
  }

  bool _isOverdue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int _notificationId(int taskId, int slot) {
    return (taskId.abs() % 100000) * 10 + slot;
  }
}

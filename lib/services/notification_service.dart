// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin? _mobileNotifications = 
      kIsWeb ? null : FlutterLocalNotificationsPlugin();
  
  bool _webPermissionGranted = false;
  final Map<int, Timer> _activeTimers = {};

  // ==================== INICIALIZAÇÃO ====================
  Future<void> initialize() async {
    print('🔔 Inicializando NotificationService...');
    if (kIsWeb) {
      await _initializeWebNotifications();
    } else {
      await _initializeMobileNotifications();
    }
  }

  // ==================== WEB ====================
  Future<void> _initializeWebNotifications() async {
    try {
      print('🌐 Web: Inicializando notificações...');
      final permission = await _requestWebPermission();
      _webPermissionGranted = permission;
      print('🌐 Web: Permissão de notificações = $_webPermissionGranted');
    } catch (e) {
      print('❌ Web: Erro: $e');
    }
  }

  Future<bool> _requestWebPermission() async {
    try {
      final permissionJS = web.Notification.requestPermission();
      final permission = await permissionJS.toDart;
      return permission == 'granted';
    } catch (e) {
      print('❌ Web: Erro permissão: $e');
      return false;
    }
  }

  // ==================== MOBILE ====================
  Future<void> _initializeMobileNotifications() async {
    try {
      print('📱 Mobile: Inicializando notificações...');
      
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _mobileNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      tz.initializeTimeZones();
      await _requestMobilePermissions();
      
      print('📱 Mobile: Notificações inicializadas com sucesso');
    } catch (e) {
      print('⚠️ Mobile: Erro ao inicializar notificações: $e');
    }
  }

  Future<void> _requestMobilePermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('📱 Mobile: Notificação clicada: ${response.payload}');
  }

  // ==================== AGENDAMENTO PRINCIPAL ====================
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? observation,
  }) async {
    print('📅 scheduleMedicationReminder CHAMADO para $medicationName');
    print('   ID: $id');
    print('   Horário: $scheduledTime');
    print('   Agora: ${DateTime.now()}');
    print('   kIsWeb = $kIsWeb');
    
    if (kIsWeb) {
      print('➡️ Chamando _scheduleWebNotification');
      _scheduleWebNotification(
        id: id,
        title: 'Hora do Remédio 💊',
        body: 'Está na hora de tomar $medicationName${observation != null ? ': $observation' : ''}',
        scheduledTime: scheduledTime,
      );
    } else {
      print('➡️ Chamando _scheduleMobileNotification');
      await _scheduleMobileNotification(
        id: id,
        medicationName: medicationName,
        scheduledTime: scheduledTime,
        observation: observation,
      );
    }
  }

  // ==================== WEB: AGENDAMENTO ====================
  void _scheduleWebNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) {
    print('📅 _scheduleWebNotification EXECUTANDO');
    print('   ID: $id');
    print('   Título: $title');
    print('   Horário alvo: $scheduledTime');
    
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);
    
    print('   Delay calculado: ${delay.inSeconds} segundos');
    
    if (delay.isNegative) {
      print('⚠️ Horário já passou, reagendando para amanhã');
      final tomorrow = DateTime(
        now.year, now.month, now.day + 1,
        scheduledTime.hour, scheduledTime.minute
      );
      _scheduleWebNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: tomorrow,
      );
      return;
    }

    if (_activeTimers.containsKey(id)) {
      print('   Cancelando timer anterior #$id');
      _activeTimers[id]!.cancel();
      _activeTimers.remove(id);
    }

    print('⏳ CRIANDO TIMER para ${delay.inSeconds} segundos...');
    
    final timer = Timer(delay, () async {
      print('⏰🔥🔥🔥 TIMER DISPAROU! Hora: ${DateTime.now()}');
      
      if (!_webPermissionGranted) {
        print('   Verificando permissão novamente...');
        _webPermissionGranted = await _requestWebPermission();
      }
      
      if (_webPermissionGranted) {
        print('   ✅ Permissão OK, mostrando notificação');
        await _showWebNotification(title: title, body: body);
        
        // Reagendar para amanhã
        final tomorrow = DateTime(
          now.year, now.month, now.day + 1,
          scheduledTime.hour, scheduledTime.minute
        );
        _scheduleWebNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: tomorrow,
        );
      } else {
        print('   ❌ Permissão negada');
      }
      
      _activeTimers.remove(id);
    });
    
    _activeTimers[id] = timer;
    print('✅✅✅ TIMER #$id CRIADO COM SUCESSO!');
  }

  // ==================== WEB: EXIBIR NOTIFICAÇÃO ====================
  Future<void> _showWebNotification({
    required String title,
    required String body,
  }) async {
    print('   Mostrando notificação: "$title" - "$body"');
    
    if (!_webPermissionGranted) {
      _webPermissionGranted = await _requestWebPermission();
      if (!_webPermissionGranted) return;
    }

    try {
      final options = web.NotificationOptions(body: body);
      final notification = web.Notification(title, options);
      
      notification.onclick = ((web.Event event) {
        print('👆 Notificação clicada');
        web.window.focus();
      }).toJS;
      
      print('✅✅✅ NOTIFICAÇÃO MOSTRADA COM SUCESSO!');
    } catch (e) {
      print('❌ Erro ao mostrar: $e');
    }
  }

  // ==================== MOBILE: AGENDAMENTO ====================
  Future<void> _scheduleMobileNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? observation,
  }) async {
    try {
      print('📱 Mobile: Agendando $medicationName para $scheduledTime');
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        'medication_channel',
        'Lembretes de Medicamentos',
        channelDescription: 'Canal para lembretes de medicamentos',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = 
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _mobileNotifications!.zonedSchedule(
        id,
        'Hora do Remédio 💊',
        'Está na hora de tomar $medicationName${observation != null ? ': $observation' : ''}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication_$id',
      );
      
      print('📱 Mobile: Notificação agendada com sucesso');
    } catch (e) {
      print('❌ Mobile: Erro ao agendar: $e');
    }
  }

  // ==================== CANCELAMENTO ====================
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      if (_activeTimers.containsKey(id)) {
        _activeTimers[id]!.cancel();
        _activeTimers.remove(id);
        print('✅ Timer #$id cancelado');
      }
    } else {
      await _mobileNotifications?.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      for (var timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();
      print('✅ Todos os timers cancelados');
    } else {
      await _mobileNotifications?.cancelAll();
    }
  }

  // ==================== TESTE ====================
  Future<void> testNotification() async {
    print('🧪 Testando notificação em 5 segundos...');
    
    await scheduleMedicationReminder(
      id: DateTime.now().millisecondsSinceEpoch,
      medicationName: 'TESTE',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      observation: 'Notificação de teste',
    );
  }

  // ==================== DISPOSE ====================
  void dispose() {
    cancelAllNotifications();
  }
}
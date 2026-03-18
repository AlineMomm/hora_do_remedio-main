// lib/services/notification_service.dart
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

  Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWebNotifications();
    } else {
      await _initializeMobileNotifications();
    }
  }

  // Inicialização para Web - CORRIGIDA
  Future<void> _initializeWebNotifications() async {
    try {
      // Verificar suporte a notificações de forma simples
      // Se chegamos aqui e o objeto web.Notification existe, já está bom
      print('🌐 Web: Inicializando notificações...');
      
      final permission = await _requestWebPermission();
      _webPermissionGranted = permission;
      
      print('🌐 Web: Permissão de notificações = $_webPermissionGranted');
    } catch (e) {
      print('❌ Web: Erro ao inicializar notificações: $e');
    }
  }

  // Solicitar permissão na web
  Future<bool> _requestWebPermission() async {
    try {
      // No package:web, Notification.requestPermission retorna um Promise
      final permissionJS = web.Notification.requestPermission();
      final permission = await permissionJS.toDart;
      return permission == 'granted';
    } catch (e) {
      print('❌ Web: Erro ao solicitar permissão: $e');
      return false;
    }
  }

  // Inicialização para Mobile
  Future<void> _initializeMobileNotifications() async {
    try {
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
    } catch (e) {
      print('⚠️ Mobile: Erro ao inicializar notificações: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? observation,
  }) async {
    if (kIsWeb) {
      await _showWebNotification(
        title: 'Hora do Remédio 💊',
        body: 'Está na hora de tomar $medicationName${observation != null ? ': $observation' : ''}',
      );
      
      _scheduleWebNotification(
        id: id,
        title: 'Hora do Remédio 💊',
        body: 'Está na hora de tomar $medicationName${observation != null ? ': $observation' : ''}',
        scheduledTime: scheduledTime,
      );
    } else {
      await _scheduleMobileNotification(
        id: id,
        medicationName: medicationName,
        scheduledTime: scheduledTime,
        observation: observation,
      );
    }
  }

  // Notificação imediata na Web
  Future<void> _showWebNotification({
    required String title,
    required String body,
  }) async {
    if (!_webPermissionGranted) {
      _webPermissionGranted = await _requestWebPermission();
      
      if (!_webPermissionGranted) {
        print('⚠️ Web: Permissão negada para notificações');
        if (kIsWeb) {
          web.window.alert('Por favor, permita notificações para receber lembretes!');
        }
        return;
      }
    }

    try {
      final options = web.NotificationOptions(
        body: body,
        // icon: '/icons/icon-192.png', // Comente se não tiver ícone
      );
      
      final notification = web.Notification(title, options);
      
      notification.onclick = ((web.Event event) {
        print('🔔 Web: Notificação clicada: $title');
        web.window.focus();
      }).toJS;
      
      print('✅ Web: Notificação mostrada: $title');
    } catch (e) {
      print('❌ Web: Erro ao mostrar notificação: $e');
    }
  }

  // Agendamento simulado na Web
  void _scheduleWebNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) {
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);
    
    if (delay.isNegative) {
      final tomorrow = scheduledTime.add(const Duration(days: 1));
      final newDelay = tomorrow.difference(now);
      
      Future.delayed(newDelay, () async {
        await _showWebNotification(title: title, body: body);
        _scheduleWebNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: tomorrow,
        );
      });
      
      print('🌐 Web: Notificação reagendada para amanhã (${newDelay.inMinutes} minutos)');
      return;
    }

    print('🌐 Web: Notificação agendada para daqui ${delay.inMinutes} minutos');
    
    Future.delayed(delay, () async {
      await _showWebNotification(title: title, body: body);
      
      final tomorrow = scheduledTime.add(const Duration(days: 1));
      _scheduleWebNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: tomorrow,
      );
    });
  }

  // Mobile
  Future<void> _scheduleMobileNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? observation,
  }) async {
    try {
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
    } catch (e) {
      print('❌ Mobile: Erro ao agendar notificação: $e');
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

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      print('🌐 Web: Cancelamento não implementado');
    } else {
      await _mobileNotifications?.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      print('🌐 Web: Cancelamento não implementado');
    } else {
      await _mobileNotifications?.cancelAll();
    }
  }
}
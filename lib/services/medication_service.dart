// lib/services/medication_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/local_storage_service.dart';
import '../models/medication_model.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class MedicationService {
  final LocalStorageService _storage = LocalStorageService();

  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  Future<List<MedicationModel>> getMedicationsList(String userId) async {
    try {
      final medications = await _storage.getMedications(userId: userId);
      final medList =
          medications.map((data) => MedicationModel.fromMap(data)).toList();

      medList.sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        if (a.minute != b.minute) return a.minute.compareTo(b.minute);
        return a.name.compareTo(b.name);
      });

      return medList;
    } catch (e) {
      print('❌ Erro ao carregar medicamentos: $e');
      return [];
    }
  }

  Future<void> addMedication(MedicationModel medication) async {
    try {
      print('🔄 Salvando medicamento: ${medication.name}');

      final medToSave = MedicationModel(
        id: medication.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : medication.id,
        userId: medication.userId,
        name: medication.name,
        hour: medication.hour,
        minute: medication.minute,
        frequency: medication.frequency,
        notes: medication.notes,
        createdAt: medication.createdAt,
      );

      await _storage.saveMedication(medToSave.toMap());

      // Agendar notificação (apenas em mobile)
      if (!kIsWeb) {
        await _scheduleNotificationForMedication(medToSave);
      }

      // Sincronizar com nuvem se estiver logado
      try {
        final syncService = SyncService();
        if (await syncService.isLoggedIn) {
          await syncService.syncMedications();
        }
      } catch (e) {
        print('⚠️ Erro ao sincronizar (não crítico): $e');
      }

      print('✅ Medicamento salvo! ID: ${medToSave.id}');
    } catch (e) {
      print('❌ Erro ao salvar: $e');
      throw 'Erro ao salvar medicamento: $e';
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    try {
      if (medication.id.isEmpty) {
        throw 'Medicamento sem ID para atualização';
      }

      print(
          '🔄 Atualizando medicamento: ${medication.name} (ID: ${medication.id})');

      final allMeds = await _storage.getMedications(userId: medication.userId);
      final index = allMeds.indexWhere((m) => m['id'] == medication.id);

      if (index >= 0) {
        allMeds[index] = medication.toMap();
        await _storage.saveAllMedications(allMeds);

        if (!kIsWeb) {
          await NotificationService()
              .cancelNotification(medication.id.hashCode);
          await _scheduleNotificationForMedication(medication);
        }

        try {
          final syncService = SyncService();
          if (await syncService.isLoggedIn) {
            await syncService.syncMedications();
          }
        } catch (e) {
          print('⚠️ Erro ao sincronizar (não crítico): $e');
        }

        print('✅ Medicamento atualizado! ID: ${medication.id}');
      } else {
        print('⚠️ Medicamento não encontrado, adicionando como novo');
        await addMedication(medication);
      }
    } catch (e) {
      print('❌ Erro ao atualizar: $e');
      throw 'Erro ao atualizar medicamento: $e';
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      if (!kIsWeb) {
        await NotificationService().cancelNotification(medicationId.hashCode);
      }

      await _storage.deleteMedication(medicationId);

      try {
        final syncService = SyncService();
        if (await syncService.isLoggedIn) {
          await syncService.syncMedications();
        }
      } catch (e) {
        print('⚠️ Erro ao sincronizar (não crítico): $e');
      }

      print('✅ Medicamento excluído! ID: $medicationId');
    } catch (e) {
      print('❌ Erro ao excluir: $e');
      throw 'Erro ao excluir medicamento: $e';
    }
  }

  Future<void> _scheduleNotificationForMedication(MedicationModel med) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      med.hour,
      med.minute,
    );

    final notificationTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await NotificationService().scheduleMedicationReminder(
      id: med.id.hashCode,
      medicationName: med.name,
      scheduledTime: notificationTime,
      observation: med.notes,
    );
  }

  Future<void> restoreAllNotifications(String userId) async {
    if (kIsWeb) return; // Não fazer nada na web

    final medications = await getMedicationsList(userId);
    for (var med in medications) {
      await _scheduleNotificationForMedication(med);
    }
  }
}

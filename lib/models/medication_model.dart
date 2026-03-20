// lib/models/medication_model.dart
import 'package:flutter/material.dart';

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final int hour;
  final int minute;
  final String frequency;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastTaken;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.hour,
    required this.minute,
    required this.frequency,
    this.notes,
    required this.createdAt,
    this.lastTaken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastTaken': lastTaken?.millisecondsSinceEpoch,
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
      frequency: map['frequency'] ?? 'Diário',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      lastTaken: map['lastTaken'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTaken'] as int)
          : null,
    );
  }

  // 🔥 NOVO: Verifica se o medicamento pode ser tomado agora
  bool get canTakeNow {
    final now = DateTime.now();
    final todayDoseTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Se nunca foi tomado, pode tomar se o horário já passou ou está próximo
    if (lastTaken == null) {
      return now.isAfter(todayDoseTime) || 
             (todayDoseTime.difference(now).inMinutes <= 30);
    }

    // Verifica se já tomou hoje
    if (wasTakenToday) {
      // Se já tomou hoje, só pode tomar novamente amanhã
      final nextDose = DateTime(
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
      return now.isAfter(nextDose);
    }

    // Se não tomou hoje, verifica se o horário de hoje já passou
    return now.isAfter(todayDoseTime) || 
           (todayDoseTime.difference(now).inMinutes <= 30);
  }

  // 🔥 NOVO: Calcula o próximo horário para tomar
  DateTime get nextDoseTime {
    final now = DateTime.now();
    final todayDose = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (lastTaken == null) {
      // Se nunca tomou, próximo horário é hoje (se ainda não passou)
      return todayDose.isAfter(now) ? todayDose : todayDose.add(Duration(days: 1));
    }

    if (!wasTakenToday && now.isBefore(todayDose)) {
      // Se não tomou hoje e ainda não passou do horário
      return todayDose;
    }

    // Próximo horário é amanhã
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  // 🔥 NOVO: Status do medicamento
  String get status {
    if (canTakeNow) {
      return 'Pode tomar';
    } else if (wasTakenToday) {
      final nextDose = nextDoseTime;
      final hours = nextDose.difference(DateTime.now()).inHours;
      final minutes = nextDose.difference(DateTime.now()).inMinutes % 60;
      return 'Próxima dose em $hours h $minutes min';
    } else {
      final nextDose = nextDoseTime;
      final hours = nextDose.difference(DateTime.now()).inHours;
      final minutes = nextDose.difference(DateTime.now()).inMinutes % 60;
      return 'Próximo horário em $hours h $minutes min';
    }
  }

  bool get wasTakenToday {
    if (lastTaken == null) return false;
    final now = DateTime.now();
    return lastTaken!.year == now.year &&
           lastTaken!.month == now.month &&
           lastTaken!.day == now.day;
  }

  bool isSameAs(MedicationModel other) {
    return name == other.name && 
           hour == other.hour && 
           minute == other.minute;
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
  
  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : hour;
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
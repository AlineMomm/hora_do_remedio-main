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

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.hour,
    required this.minute,
    required this.frequency,
    this.notes,
    required this.createdAt,
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
    );
  }

  // NOVO: Método para comparar se é o mesmo medicamento (ignorando ID)
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
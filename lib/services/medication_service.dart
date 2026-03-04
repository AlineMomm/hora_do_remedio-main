import '../services/local_storage_service.dart';
import '../models/medication_model.dart';

class MedicationService {
  final LocalStorageService _storage = LocalStorageService();

  MedicationService._privateConstructor();
  static final MedicationService _instance = MedicationService._privateConstructor();
  factory MedicationService() => _instance;

  Future<List<MedicationModel>> getMedicationsList(String userId) async {
    try {
      final medications = await _storage.getMedications(userId: userId);
      return medications.map((data) => MedicationModel.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao carregar medicamentos: $e');
      return [];
    }
  }

  Future<void> addMedication(MedicationModel medication) async {
    try {
      print('🔄 Salvando medicamento: ${medication.name}');
      
      // Se não tem ID, gera um
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
      
      await _storage.saveMedication(medication.toMap());
      print('✅ Medicamento atualizado! ID: ${medication.id}');
    } catch (e) {
      print('❌ Erro ao atualizar: $e');
      throw 'Erro ao atualizar medicamento: $e';
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _storage.deleteMedication(medicationId);
      print('✅ Medicamento excluído! ID: $medicationId');
    } catch (e) {
      print('❌ Erro ao excluir: $e');
      throw 'Erro ao excluir medicamento: $e';
    }
  }
}
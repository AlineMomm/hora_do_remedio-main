import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final LocalStorageService _storage = LocalStorageService();
  UserModel? currentUser;

  AuthService._privateConstructor();
  static final AuthService _instance = AuthService._privateConstructor();
  factory AuthService() => _instance;

  // Gerar ID único
  String _generateUid() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<UserModel?> registerWithEmailAndPassword(
      String name, String email, String password) async {
    try {
      print('🔄 Tentando registrar: $email');
      
      // Verificar se email já existe
      final existingUser = await _storage.getUserByEmail(email);
      if (existingUser != null && existingUser.isNotEmpty) {
        throw 'Este e-mail já está cadastrado';
      }
      
      // Criar novo usuário
      final newUser = UserModel(
        uid: _generateUid(),
        name: name,
        email: email,
      );
      
      // Salvar no storage
      await _storage.saveUser(newUser.toMap());
      
      // Definir como usuário atual
      currentUser = newUser;
      await _storage.setCurrentUser(newUser.uid);
      
      print('✅ Usuário criado: ${newUser.uid}');
      return currentUser;
    } catch (e) {
      print('❌ Erro no registro: $e');
      rethrow;
    }
  }

  Future<UserModel?> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      print('🔄 Tentando login: $email');
      
      // Buscar usuário pelo email
      final userData = await _storage.getUserByEmail(email);
      
      if (userData == null || userData.isEmpty) {
        throw 'Usuário não encontrado';
      }
      
      // Converter para UserModel
      currentUser = UserModel.fromMap(userData);
      
      // Definir como usuário atual
      await _storage.setCurrentUser(currentUser!.uid);
      
      print('✅ Login bem-sucedido: ${currentUser!.uid}');
      return currentUser;
    } catch (e) {
      print('❌ Erro no login: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _storage.saveUser(updatedUser.toMap());
      currentUser = updatedUser;
      print('✅ Perfil atualizado!');
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _storage.setCurrentUser(null);
    currentUser = null;
    print('✅ Usuário deslogado');
  }

  Future<UserModel?> getCurrentUser() async {
    if (currentUser != null) return currentUser;
    
    final userId = await _storage.getCurrentUserId();
    if (userId == null) return null;
    
    final userData = await _storage.getUserById(userId);
    if (userData == null) return null;
    
    currentUser = UserModel.fromMap(userData);
    return currentUser;
  }
}
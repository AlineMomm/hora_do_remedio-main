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
      
      // Validar senha
      if (password.length < 6) {
        throw 'Senha muito fraca (mínimo 6 caracteres)';
      }
      
      // Validar email
      if (!email.contains('@') || !email.contains('.')) {
        throw 'E-mail inválido';
      }
      
      // Criar novo usuário
      final newUser = UserModel(
        uid: _generateUid(),
        name: name, // Nome do cadastro
        email: email,
      );
      
      // Salvar no storage
      await _storage.saveUser(newUser.toMap());
      
      // Definir como usuário atual
      currentUser = newUser;
      await _storage.setCurrentUser(newUser.uid);
      
      print('✅ Usuário criado: ${newUser.uid} - Nome: ${newUser.name}');
      return currentUser;
    } catch (e) {
      print('❌ Erro no registro: $e');
      throw 'Erro no cadastro: $e';
    }
  }

  Future<UserModel?> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      print('🔄 Tentando login: $email');
      
      // Validar email
      if (!email.contains('@') || !email.contains('.')) {
        throw 'E-mail inválido';
      }
      
      // Buscar usuário pelo email
      final userData = await _storage.getUserByEmail(email);
      
      if (userData == null || userData.isEmpty) {
        throw 'Usuário não encontrado';
      }
      
      // Converter para UserModel
      currentUser = UserModel.fromMap(userData);
      
      // Definir como usuário atual
      await _storage.setCurrentUser(currentUser!.uid);
      
      print('✅ Login bem-sucedido: ${currentUser!.uid} - Nome: ${currentUser!.name}');
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
      print('✅ Perfil atualizado! Nome: ${updatedUser.name}');
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
    if (currentUser != null) {
      print('📌 Usuário atual em memória: ${currentUser!.name}');
      return currentUser;
    }
    
    final userId = await _storage.getCurrentUserId();
    if (userId == null) {
      print('📌 Nenhum usuário logado');
      return null;
    }
    
    final userData = await _storage.getUserById(userId);
    if (userData == null) {
      print('📌 Dados do usuário não encontrados');
      return null;
    }
    
    currentUser = UserModel.fromMap(userData);
    print('📌 Usuário carregado do storage: ${currentUser!.name}');
    return currentUser;
  }
}
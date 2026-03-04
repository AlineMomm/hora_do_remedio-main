import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../models/medication_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  // Configurações específicas para Web
  static FirebaseOptions get firebaseOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyC_gGil9MXuz6agSXHC05vTS8c9FV7i07s",
        appId: "1:828522686230:web:1376d1593159d158671237", // ID da web
        messagingSenderId: "828522686230",
        projectId: "hora-do-remedio-165b3",
        authDomain: "hora-do-remedio-165b3.firebaseapp.com", // Necessário para web
        storageBucket: "hora-do-remedio-165b3.firebasestorage.app",
      );
    } else {
      // Android/iOS
      return const FirebaseOptions(
        apiKey: "AIzaSyC_gGil9MXuz6agSXHC05vTS8c9FV7i07s",
        appId: "1:828522686230:android:1376d1593159d158671237",
        messagingSenderId: "828522686230",
        projectId: "hora-do-remedio-165b3",
        storageBucket: "hora-do-remedio-165b3.firebasestorage.app",
      );
    }
  }

  // ==================== INICIALIZAÇÃO ====================
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: firebaseOptions,
      );
      
      // Configurações específicas para web
      if (kIsWeb) {
        await _configureWebAuth();
      }
      
      print('✅ Firebase inicializado com sucesso (${kIsWeb ? "Web" : "Android"})');
    } catch (e) {
      print('❌ Erro ao inicializar Firebase: $e');
    }
  }

  // Configurações adicionais para web
  static Future<void> _configureWebAuth() async {
    // Configurar persistência para web
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  // ==================== AUTENTICAÇÃO ====================
  Future<UserModel?> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw 'Erro ao criar usuário';

      // Atualizar nome do usuário
      await user.updateDisplayName(name);
      await user.reload();

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      print('✅ Usuário criado no Firebase: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        throw 'Este e-mail já está cadastrado';
      } else if (e.code == 'weak-password') {
        throw 'Senha muito fraca (mínimo 6 caracteres)';
      } else {
        throw 'Erro no cadastro: ${e.message}';
      }
    } catch (e) {
      print('❌ Erro no registro: $e');
      throw 'Erro no cadastro: $e';
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw 'Usuário não encontrado';

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Usuário',
          email: user.email!,
        );
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        return userModel;
      }

      return UserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        throw 'Senha incorreta';
      } else if (e.code == 'invalid-email') {
        throw 'E-mail inválido';
      } else {
        throw 'Erro no login: ${e.message}';
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      throw 'Erro no login: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== MEDICAMENTOS ====================
  Future<void> syncMedicationsToCloud(String userId, List<MedicationModel> medications) async {
    try {
      final batch = _firestore.batch();
      final userMedsRef = _firestore.collection('users').doc(userId).collection('medications');

      final existingSnapshot = await userMedsRef.get();
      
      for (var doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (var med in medications) {
        final docRef = userMedsRef.doc(med.id);
        batch.set(docRef, {
          ...med.toMap(),
          'lastSync': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Medicamentos sincronizados: ${medications.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar: $e');
      throw 'Erro ao sincronizar com a nuvem';
    }
  }

  Future<List<MedicationModel>> loadMedicationsFromCloud(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .orderBy('createdAt', descending: true)
          .get();

      final medications = snapshot.docs.map((doc) {
        return MedicationModel.fromMap(doc.data());
      }).toList();

      print('✅ Medicamentos carregados da nuvem: ${medications.length}');
      return medications;
    } catch (e) {
      print('❌ Erro ao carregar da nuvem: $e');
      throw 'Erro ao carregar dados da nuvem';
    }
  }

  // ==================== PERFIL ====================
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      print('✅ Perfil atualizado no Firebase');
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      throw 'Erro ao atualizar perfil na nuvem';
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar perfil: $e');
      return null;
    }
  }
}
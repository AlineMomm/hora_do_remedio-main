import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Por enquanto, só configuramos a Web
    if (kIsWeb) {
      return web;
    }
    
    throw UnsupportedError(
      'FirebaseOptions não configurados para esta plataforma.\n'
      'Você precisa configurar Android/iOS/etc no Firebase Console e adicionar aqui.'
    );
  }

  // Configuração da Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBdTgD-WoJJ_vWBQRN-5no-GekyBJVD554',
    appId: '1:828522686230:web:e1425ab99031186e671237',
    messagingSenderId: '828522686230',
    projectId: 'hora-do-remedio-165b3',
    authDomain: 'hora-do-remedio-165b3.firebaseapp.com',
    storageBucket: 'hora-do-remedio-165b3.firebasestorage.app',
    measurementId: 'G-DB9RQRVWTE',
  );
}
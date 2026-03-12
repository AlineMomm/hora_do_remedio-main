import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/medication_list_page.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FirebaseService.initialize();
    print('✅ Firebase inicializado com sucesso');
  } catch (e) {
    print('❌ Erro ao inicializar Firebase: $e');
  }
  
  // Carregar configurações usando a instância única
  final settingsService = SettingsService();
  await settingsService.loadSettings();
  
  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  
  const MyApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settingsService,
      child: Consumer<SettingsService>(
        builder: (context, settings, child) {
          print('🔄 Reconstruindo tema - Fonte: ${settings.currentFontSize.label}');
          
          return MaterialApp(
            title: 'Hora do Remédio',
            theme: _buildTheme(),
            home: const MedicationListPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF388E3C),
        error: const Color(0xFFD32F2F),
        background: Colors.white,
        surface: const Color(0xFFF5F5F5),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: const Color(0xFF212121),
        onSurface: const Color(0xFF212121),
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      useMaterial3: false,
    );
  }
}
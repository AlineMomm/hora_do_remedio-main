import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSize {
  pequeno(14.0, 'Pequeno'),
  normal(16.0, 'Normal'),
  grande(18.0, 'Grande'),
  muitoGrande(20.0, 'Muito Grande'),
  enorme(22.0, 'Enorme');

  final double value;
  final String label;
  const FontSize(this.value, this.label);
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _fontSizeKey = 'font_size';

  // Fonte padrão
  FontSize _currentFontSize = FontSize.normal;

  FontSize get currentFontSize => _currentFontSize;

  // Calcular tamanho dos botões baseado na fonte
  double get buttonHeight {
    switch (_currentFontSize) {
      case FontSize.pequeno:
        return 45.0;
      case FontSize.normal:
        return 50.0;
      case FontSize.grande:
        return 55.0;
      case FontSize.muitoGrande:
        return 60.0;
      case FontSize.enorme:
        return 65.0;
    }
  }
double get iconSize {
  switch (_currentFontSize) {
    case FontSize.pequeno:
      return 20;
    case FontSize.normal:
      return 24;
    case FontSize.grande:
      return 28;
    case FontSize.muitoGrande:
      return 32;
    case FontSize.enorme:
      return 36;
  }
}
  double get buttonFontSize {
    switch (_currentFontSize) {
      case FontSize.pequeno:
        return 16.0;
      case FontSize.normal:
        return 18.0;
      case FontSize.grande:
        return 20.0;
      case FontSize.muitoGrande:
        return 22.0;
      case FontSize.enorme:
        return 24.0;
    }
  }

  // Carregar configurações salvas
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final fontSizeIndex = prefs.getInt(_fontSizeKey) ?? 1; // Normal como padrão
    _currentFontSize = FontSize.values[fontSizeIndex];
    
    print('✅ Configurações carregadas: Fonte=${_currentFontSize.label}');
    notifyListeners();
  }

  // Salvar tamanho da fonte
  Future<void> setFontSize(FontSize size) async {
    print('📝 Alterando fonte de ${_currentFontSize.label} para ${size.label}');
    _currentFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontSizeKey, size.index);
    print('✅ Tamanho da fonte alterado: ${size.label}');
    notifyListeners();
  }

  // Obter estilo de texto com tamanho configurado
  TextStyle getTextStyle({
  double? size,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  const double baseFontSize = 16.0; // tamanho "Normal"
  final double scaleFactor = _currentFontSize.value / baseFontSize;

  final double baseSize = size ?? baseFontSize;
  final double finalSize = baseSize * scaleFactor;

  return TextStyle(
    fontSize: finalSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

  // Estilo para botões elevados
  ButtonStyle getElevatedButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? const Color(0xFF1976D2),
      foregroundColor: foregroundColor ?? Colors.white,
      minimumSize: Size(double.infinity, buttonHeight),
      textStyle: TextStyle(
        fontSize: buttonFontSize,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      elevation: 2,
    );
  }

  // Estilo para botões de texto
  ButtonStyle getTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: const Color(0xFF1976D2),
      textStyle: TextStyle(
        fontSize: buttonFontSize,
      ),
    );
  }

  // Estilo para FloatingActionButton
  FloatingActionButtonThemeData getFloatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF388E3C),
      foregroundColor: Colors.white,
      elevation: 4,
      sizeConstraints: BoxConstraints.tightFor(
        width: buttonHeight + 10,
        height: buttonHeight + 10,
      ),
    );
  }
  
}
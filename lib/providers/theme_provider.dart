import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = StorageService.isDarkMode;
  double _fontSize = StorageService.fontSize;
  String _fontFamily = StorageService.fontFamily;
  String _reciterName = StorageService.reciterName;

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get reciterName => _reciterName;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    StorageService.setFontSize(size);
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    StorageService.setFontFamily(family);
    notifyListeners();
  }

  void updateReciterName(String name) {
    _reciterName = name;
    StorageService.setReciterName(name);
    notifyListeners();
  }
}

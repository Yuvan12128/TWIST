import 'package:flutter/material.dart';
import 'app_language.dart';
import '../services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService;

  AppLanguage get currentLanguage => AppLanguage.en;
  Locale get locale => const Locale('en', '');

  LanguageProvider(this._storageService);

  Future<void> setLanguage(AppLanguage language) async {
    // English-only V1: locked to English
    await _storageService.saveLanguageCode(AppLanguage.en.code);
    notifyListeners();
  }

  bool get hasSelectedInitialLanguage => true;
}

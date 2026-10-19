import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_language.dart';
import 'translations/en.dart';
import 'translations/ta.dart';
import 'translations/tanglish.dart';

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.en: enTranslations,
    AppLanguage.ta: taTranslations,
    AppLanguage.tanglish: tanglishTranslations,
  };

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return localizations ?? AppLocalizations(AppLanguage.en);
  }

  String translate(String key) {
    final map = _translations[language];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    // Fallback to English
    final enMap = _translations[AppLanguage.en];
    if (enMap != null && enMap.containsKey(key)) {
      return enMap[key]!;
    }
    return key;
  }

  static List<LocalizationsDelegate<dynamic>> localizationsDelegates(AppLanguage language) => [
    AppLocalizationsDelegate(language),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    const FallbackMaterialLocalizationsDelegate(),
    const FallbackCupertinoLocalizationsDelegate(),
  ];
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppLanguage language;

  const AppLocalizationsDelegate(this.language);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => old.language != language;
}

class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}

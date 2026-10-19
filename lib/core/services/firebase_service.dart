import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;
  static bool get isFirebaseReady => _initialized;

  static FirebaseAuth? get auth => _initialized ? FirebaseAuth.instance : null;
  static FirebaseFirestore? get firestore => _initialized ? FirebaseFirestore.instance : null;
  static FirebaseAnalytics? get analytics => _initialized ? FirebaseAnalytics.instance : null;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      dev.log('🔥 Firebase initialized successfully.', name: 'FirebaseService');
    } catch (e) {
      _initialized = false;
      dev.log(
        '⚠️ Firebase not initialized (${e.toString()}). Using offline/local persistent storage engine.',
        name: 'FirebaseService',
      );
    }
  }
}

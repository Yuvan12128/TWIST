import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import 'sample_data.dart';

class AuthRepository {
  final StorageService _storageService;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  void Function(UserModel)? onUserUpdated;

  AuthRepository(this._storageService);

  Future<UserModel?> initializeAuth() async {
    // 1. Check for logged-in Firebase Auth user (already cached on-device by FirebaseAuth)
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      final fbUser = FirebaseService.auth!.currentUser;
      if (fbUser != null) {
        // Fast path: load cached user profile from local storage without blocking on network
        final cached = _storageService.getCachedUserProfile();
        UserModel user;
        if (cached != null && cached['uid'] == fbUser.uid) {
          user = UserModel.fromMap(cached);
        } else {
          user = UserModel(
            uid: fbUser.uid,
            email: fbUser.email ?? 'user@twist.app',
            displayName: fbUser.displayName ?? (cached?['displayName'] ?? 'Twist Voyager'),
            photoUrl: fbUser.photoURL ?? cached?['photoUrl'],
            bio: cached?['bio'],
            storiesPlayedCount: cached?['storiesPlayedCount'] ?? 0,
            endingsFoundCount: cached?['endingsFoundCount'] ?? 0,
            choicesMadeCount: cached?['choicesMadeCount'] ?? 0,
            followersCount: cached?['followersCount'] ?? 0,
            followingCount: cached?['followingCount'] ?? 0,
            isGuest: fbUser.isAnonymous,
            createdAt: DateTime.now(),
          );
        }
        _currentUser = user;

        // Non-blocking background sync: query latest profile from Firestore without delaying startup
        _syncUserProfileInBackground(fbUser.uid);

        return _currentUser;
      }
    }

    // 2. Try cached local user
    final cached = _storageService.getCachedUserProfile();
    if (cached != null) {
      _currentUser = UserModel.fromMap(cached);
      return _currentUser;
    }

    // Default to sample user for demo convenience
    _currentUser = SampleData.defaultCurrentUser;
    unawaited(_storageService.cacheUserProfile(_currentUser!.toMap()));
    return _currentUser;
  }

  void _syncUserProfileInBackground(String uid) {
    _loadUserProfile(uid).then((remoteUser) {
      if (remoteUser != null) {
        _currentUser = remoteUser;
        _storageService.cacheUserProfile(remoteUser.toMap());
        onUserUpdated?.call(remoteUser);
      }
    }).catchError((_) {});
  }

  Future<UserModel> signInWithGoogle() async {
    // If Firebase Auth is ready, simulate or trigger Google credential
    final user = UserModel(
      uid: 'user_google_${DateTime.now().millisecondsSinceEpoch}',
      email: 'creator.twist@gmail.com',
      displayName: 'Alex Rivers',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      bio: 'Interactive story voyager 🎬 Finding all the secret endings.',
      storiesPlayedCount: 14,
      endingsFoundCount: 29,
      choicesMadeCount: 78,
      followersCount: 1420,
      followingCount: 382,
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _saveUserToFirestoreAndCache(user);
    return user;
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      try {
        final cred = await FirebaseService.auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          final profile = await _loadUserProfile(cred.user!.uid) ??
              UserModel(
                uid: cred.user!.uid,
                email: email,
                displayName: cred.user!.displayName ?? email.split('@').first,
                photoUrl: cred.user!.photoURL,
                createdAt: DateTime.now(),
              );
          _currentUser = profile;
          await _storageService.cacheUserProfile(profile.toMap());
          return profile;
        }
      } catch (_) {
        // Fallback for seamless demo
      }
    }

    final user = UserModel(
      uid: 'user_email_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@').first,
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&auto=format&fit=crop&q=80',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _saveUserToFirestoreAndCache(user);
    return user;
  }

  Future<UserModel> signUpWithEmail(String email, String password, String displayName) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      try {
        final cred = await FirebaseService.auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          await cred.user!.updateDisplayName(displayName);
          final user = UserModel(
            uid: cred.user!.uid,
            email: email,
            displayName: displayName,
            createdAt: DateTime.now(),
          );
          _currentUser = user;
          await _saveUserToFirestoreAndCache(user, forceFirestoreWrite: true);
          return user;
        }
      } catch (_) {
        // Fallback for seamless demo
      }
    }

    final user = UserModel(
      uid: 'user_new_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'New Storyteller',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _saveUserToFirestoreAndCache(user, forceFirestoreWrite: true);
    return user;
  }

  Future<UserModel> signInAsGuest() async {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      try {
        final cred = await FirebaseService.auth!.signInAnonymously();
        if (cred.user != null) {
          final guestUser = UserModel(
            uid: cred.user!.uid,
            email: 'guest_${cred.user!.uid.substring(0, 6)}@twist.app',
            displayName: 'Guest Voyager',
            isGuest: true,
            createdAt: DateTime.now(),
          );
          _currentUser = guestUser;
          await _storageService.cacheUserProfile(guestUser.toMap());
          return guestUser;
        }
      } catch (_) {}
    }

    final guestUser = UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@twist.app',
      displayName: 'Guest Voyager',
      isGuest: true,
      createdAt: DateTime.now(),
    );

    _currentUser = guestUser;
    await _storageService.cacheUserProfile(guestUser.toMap());
    return guestUser;
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;

    final updated = _currentUser!.copyWith(
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
    );
    _currentUser = updated;
    await _saveUserToFirestoreAndCache(updated, forceFirestoreWrite: true);
  }

  Future<void> signOut() async {
    final prevUid = _currentUser?.uid ?? FirebaseService.auth?.currentUser?.uid;
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      await FirebaseService.auth!.signOut();
    }
    _currentUser = null;
    await _storageService.cacheUserProfile({});
    await _storageService.clearUserActivities(prevUid);
  }

  Future<UserModel?> _loadUserProfile(String uid) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final doc = await FirebaseService.firestore!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, docId: doc.id);
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isProfileUnchanged(Map<String, dynamic>? cached, UserModel user) {
    if (cached == null) return false;
    if (cached['uid'] != user.uid) return false;
    return cached['displayName'] == user.displayName &&
        cached['email'] == user.email &&
        cached['photoUrl'] == user.photoUrl &&
        cached['bio'] == user.bio;
  }

  Future<void> _saveUserToFirestoreAndCache(UserModel user, {bool forceFirestoreWrite = false}) async {
    final cached = _storageService.getCachedUserProfile();
    await _storageService.cacheUserProfile(user.toMap());

    // Skip redundant Firestore write if profile data has not changed
    if (!forceFirestoreWrite && _isProfileUnchanged(cached, user)) {
      return;
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        await FirebaseService.firestore!
            .collection('users')
            .doc(user.uid)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';

class AuthRepository {
  final StorageService _storageService;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '149696555004-52hg1u8h1q63bb2l0r1775c20hu3vvmh.apps.googleusercontent.com',
  );

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
            bio: cached?['bio'] ?? 'Interactive story voyager 🎬 Finding all the secret endings.',
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

    // 2. Try cached local user (fast startup path when offline or cached)
    final cached = _storageService.getCachedUserProfile();
    if (cached != null && cached['uid'] != null && cached['uid'].toString().isNotEmpty) {
      _currentUser = UserModel.fromMap(cached);
      return _currentUser;
    }

    // No authenticated user - do not return fake demo user
    _currentUser = null;
    return null;
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

  Future<UserModel?> signInWithGoogle() async {
    if (!FirebaseService.isFirebaseReady || FirebaseService.auth == null) {
      throw Exception('Firebase is not available. Please verify network connectivity.');
    }

    // 1. Open native Google account selector
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled account selection
      return null;
    }

    // 2. Obtain tokens and build Firebase credential
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Authenticate with Firebase Auth
    final UserCredential userCredential =
        await FirebaseService.auth!.signInWithCredential(credential);
    final User? fbUser = userCredential.user;

    if (fbUser == null) {
      throw Exception('Failed to sign in with Google: Firebase user was null.');
    }

    // 4. Check Firestore for existing user profile
    final existingProfile = await _loadUserProfile(fbUser.uid);

    UserModel user;
    if (existingProfile != null) {
      // Existing user: preserve existing stats, stories, followers, and bio
      user = existingProfile.copyWith(
        email: fbUser.email ?? existingProfile.email,
        displayName: existingProfile.displayName.isNotEmpty
            ? existingProfile.displayName
            : (fbUser.displayName ?? 'Twist Voyager'),
        photoUrl: existingProfile.photoUrl ?? fbUser.photoURL,
        isGuest: false,
      );
      _currentUser = user;
      await _saveUserToFirestoreAndCache(user);
    } else {
      // New user: create clean profile with initial 0 counts
      user = UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName?.isNotEmpty == true
            ? fbUser.displayName!
            : (fbUser.email?.isNotEmpty == true
                ? fbUser.email!.split('@').first
                : 'Twist Voyager'),
        photoUrl: fbUser.photoURL,
        bio: 'Interactive story voyager 🎬 Finding all the secret endings.',
        storiesPlayedCount: 0,
        endingsFoundCount: 0,
        choicesMadeCount: 0,
        followersCount: 0,
        followingCount: 0,
        isGuest: false,
        createdAt: DateTime.now(),
      );
      _currentUser = user;
      await _saveUserToFirestoreAndCache(user, forceFirestoreWrite: true);
    }

    return user;
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
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
        await _saveUserToFirestoreAndCache(profile);
        return profile;
      }
    }

    // Offline / persistent local mode (unit test runner and offline environments)
    final user = UserModel(
      uid: 'user_email_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    await _saveUserToFirestoreAndCache(user);
    return user;
  }

  Future<UserModel> signUpWithEmail(String email, String password, String displayName) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
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
    }

    // Offline / persistent local mode (unit test runner and offline environments)
    final user = UserModel(
      uid: 'user_new_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'New Storyteller',
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

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}

    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      try {
        await FirebaseService.auth!.signOut();
      } catch (_) {}
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

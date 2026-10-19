import 'dart:async';
import '../models/activity_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import 'sample_data.dart';

class ActivityRepository {
  final StorageService? storageService;
  final bool enableSampleFallback;

  bool get shouldUseSampleFallback => enableSampleFallback;

  List<ActivityModel> _activities = [];
  String? _cachedUserId;

  ActivityRepository({
    this.storageService,
    this.enableSampleFallback = false,
  }) {
    // Clear stale local activity data from previous test accounts
    final currentUid = FirebaseService.auth?.currentUser?.uid ??
        storageService?.getCachedUserProfile()?['uid'] as String?;
    storageService?.clearStaleActivityData(currentUserId: currentUid);

    if (shouldUseSampleFallback) {
      _activities = SampleData.getActivities();
    }
  }

  Future<List<ActivityModel>> getActivities({
    String? userId,
    String? filter,
    bool forceRefresh = false,
  }) async {
    final uid = userId ??
        FirebaseService.auth?.currentUser?.uid ??
        storageService?.getCachedUserProfile()?['uid'] as String?;

    // If no user is logged in
    if (uid == null || uid.isEmpty) {
      if (shouldUseSampleFallback) {
        return _filterList(_activities, filter);
      }
      _activities = [];
      _cachedUserId = null;
      return [];
    }

    // If user changed, invalidate in-memory cache immediately
    if (_cachedUserId != null && _cachedUserId != uid) {
      _activities = [];
      _cachedUserId = null;
    }

    // 1. Return in-memory cache if valid and not forceRefresh
    if (!forceRefresh && _cachedUserId == uid && _activities.isNotEmpty) {
      return _filterList(_activities, filter);
    }

    // 2. Try user-specific local storage cache
    final localService = storageService;
    if (!forceRefresh && localService != null) {
      final cachedList = localService.getCachedActivities(uid);
      if (cachedList != null && cachedList.isNotEmpty) {
        _activities = cachedList.map((m) => ActivityModel.fromMap(m)).toList();
        _cachedUserId = uid;
        // Background sync latest from Firestore
        unawaited(_fetchFromFirestore(uid).catchError((_) {}));
        return _filterList(_activities, filter);
      }
    }

    // 3. Fetch from Firestore
    await _fetchFromFirestore(uid);

    return _filterList(_activities, filter);
  }

  Future<void> _fetchFromFirestore(String uid) async {
    if (!FirebaseService.isFirebaseReady || FirebaseService.firestore == null) {
      if (shouldUseSampleFallback && _activities.isEmpty) {
        _activities = SampleData.getActivities();
        _cachedUserId = uid;
      }
      return;
    }

    try {
      List<ActivityModel> remoteActivities = [];

      // Pattern 1: users/{uid}/activities subcollection
      final subSnap = await FirebaseService.firestore!
          .collection('users')
          .doc(uid)
          .collection('activities')
          .limit(50)
          .get();

      if (subSnap.docs.isNotEmpty) {
        remoteActivities = subSnap.docs.map((d) {
          return ActivityModel.fromMap(d.data(), docId: d.id);
        }).toList();
      } else {
        // Pattern 2: root activities collection filtered by userId
        final rootSnap = await FirebaseService.firestore!
            .collection('activities')
            .where('userId', isEqualTo: uid)
            .limit(50)
            .get();

        if (rootSnap.docs.isNotEmpty) {
          remoteActivities = rootSnap.docs.map((d) {
            return ActivityModel.fromMap(d.data(), docId: d.id);
          }).toList();
        }
      }

      remoteActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _activities = remoteActivities;
      _cachedUserId = uid;

      final localService = storageService;
      if (localService != null) {
        await localService.cacheActivities(
          uid,
          remoteActivities.map((a) => a.toMap()).toList(),
        );
      }
    } catch (_) {
      // In offline scenario, keep existing user-specific cache
    }
  }

  List<ActivityModel> _filterList(List<ActivityModel> list, String? filter) {
    if (filter == null || filter == 'All') {
      return List.unmodifiable(list);
    }
    return list.where((a) => a.type.toLowerCase() == filter.toLowerCase()).toList();
  }

  Future<void> markAsRead(String id, {String? userId}) async {
    final index = _activities.indexWhere((a) => a.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(isRead: true);
    }

    final uid = userId ?? _cachedUserId ?? FirebaseService.auth?.currentUser?.uid;
    final localService = storageService;
    if (localService != null && uid != null) {
      await localService.cacheActivities(
        uid,
        _activities.map((a) => a.toMap()).toList(),
      );
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null && uid != null) {
      try {
        final subDoc = FirebaseService.firestore!
            .collection('users')
            .doc(uid)
            .collection('activities')
            .doc(id);
        final snap = await subDoc.get();
        if (snap.exists) {
          await subDoc.update({'isRead': true});
        } else {
          final rootDoc = FirebaseService.firestore!.collection('activities').doc(id);
          final rootSnap = await rootDoc.get();
          if (rootSnap.exists) {
            await rootDoc.update({'isRead': true});
          }
        }
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    _activities = _activities.map((a) => a.copyWith(isRead: true)).toList();

    final uid = userId ?? _cachedUserId ?? FirebaseService.auth?.currentUser?.uid;
    final localService = storageService;
    if (localService != null && uid != null) {
      await localService.cacheActivities(
        uid,
        _activities.map((a) => a.toMap()).toList(),
      );
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null && uid != null) {
      try {
        final subSnap = await FirebaseService.firestore!
            .collection('users')
            .doc(uid)
            .collection('activities')
            .where('isRead', isEqualTo: false)
            .get();
        for (final doc in subSnap.docs) {
          await doc.reference.update({'isRead': true});
        }
      } catch (_) {}
    }
  }

  Future<void> clearUserActivities([String? userId]) async {
    final uid = userId ?? _cachedUserId ?? FirebaseService.auth?.currentUser?.uid;
    _activities = [];
    _cachedUserId = null;
    final localService = storageService;
    if (localService != null && uid != null) {
      await localService.clearUserActivities(uid);
    }
  }

  void clearCache() {
    _activities = [];
    _cachedUserId = null;
  }

  int getUnreadCount() {
    return _activities.where((a) => !a.isRead).length;
  }
}

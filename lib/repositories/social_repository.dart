import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../models/story_model.dart';

class SocialRepository {
  final StorageService? _storageService;
  StorageService? get storageService => _storageService;

  // In-memory fallback for offline test environments
  final Set<String> _localFollows = {};

  SocialRepository([this._storageService]);

  String? get _currentUid => FirebaseService.auth?.currentUser?.uid;

  /// Deterministic follow document ID: {followerId}_{followingId}
  String _followDocId(String followerId, String followingId) =>
      '${followerId}_$followingId';

  /// Check if the currently logged-in user is following [targetUserId]
  Future<bool> isFollowing(String targetUserId, {String? currentUserId}) async {
    final currentUid = currentUserId ?? _currentUid;
    if (currentUid == null || currentUid.isEmpty || targetUserId.isEmpty) {
      return false;
    }
    if (currentUid == targetUserId) return false;

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final doc = await FirebaseService.firestore!
            .collection('follows')
            .doc(_followDocId(currentUid, targetUserId))
            .get();
        return doc.exists;
      } catch (_) {
        return _localFollows.contains(_followDocId(currentUid, targetUserId));
      }
    }

    return _localFollows.contains(_followDocId(currentUid, targetUserId));
  }

  /// Follow [targetUserId]
  Future<bool> followUser(String targetUserId, {UserModel? currentUser}) async {
    final currentUid = _currentUid ?? currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty || targetUserId.isEmpty) {
      return false;
    }
    if (currentUid == targetUserId) return false;

    final docId = _followDocId(currentUid, targetUserId);
    _localFollows.add(docId);

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final batch = FirebaseService.firestore!.batch();

        final followRef = FirebaseService.firestore!.collection('follows').doc(docId);
        batch.set(followRef, {
          'followerId': currentUid,
          'followingId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add activity record for the followed user
        final activityRef = FirebaseService.firestore!.collection('activities').doc();
        final actorName = currentUser?.displayName ??
            FirebaseService.auth?.currentUser?.displayName ??
            'A voyager';
        final actorPhoto = currentUser?.photoUrl ??
            FirebaseService.auth?.currentUser?.photoURL;

        batch.set(activityRef, {
          'userId': targetUserId,
          'title': 'New Follower',
          'subtitle': '$actorName started following you',
          'type': 'follow',
          'actorId': currentUid,
          'avatarUrl': actorPhoto,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        return true;
      } catch (e) {
        // Fallback: direct set if batch fails
        try {
          await FirebaseService.firestore!
              .collection('follows')
              .doc(docId)
              .set({
            'followerId': currentUid,
            'followingId': targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        } catch (_) {
          return true;
        }
      }
    }

    return true;
  }

  /// Unfollow [targetUserId]
  Future<bool> unfollowUser(String targetUserId, {String? currentUserId}) async {
    final currentUid = currentUserId ?? _currentUid;
    if (currentUid == null || currentUid.isEmpty || targetUserId.isEmpty) {
      return false;
    }

    final docId = _followDocId(currentUid, targetUserId);
    _localFollows.remove(docId);

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        await FirebaseService.firestore!.collection('follows').doc(docId).delete();
        return true;
      } catch (_) {
        return true;
      }
    }

    return true;
  }

  /// Get live follower count for [userId]
  Future<int> getFollowersCount(String userId) async {
    if (userId.isEmpty) return 0;

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final countSnap = await FirebaseService.firestore!
            .collection('follows')
            .where('followingId', isEqualTo: userId)
            .count()
            .get();
        return countSnap.count ?? 0;
      } catch (_) {
        // Fallback query if count() is not supported on offline/mock
        try {
          final snap = await FirebaseService.firestore!
              .collection('follows')
              .where('followingId', isEqualTo: userId)
              .limit(100)
              .get();
          return snap.docs.length;
        } catch (_) {
          return _localFollows
              .where((id) => id.endsWith('_$userId'))
              .length;
        }
      }
    }

    return _localFollows.where((id) => id.endsWith('_$userId')).length;
  }

  /// Get live following count for [userId]
  Future<int> getFollowingCount(String userId) async {
    if (userId.isEmpty) return 0;

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final countSnap = await FirebaseService.firestore!
            .collection('follows')
            .where('followerId', isEqualTo: userId)
            .count()
            .get();
        return countSnap.count ?? 0;
      } catch (_) {
        try {
          final snap = await FirebaseService.firestore!
              .collection('follows')
              .where('followerId', isEqualTo: userId)
              .limit(100)
              .get();
          return snap.docs.length;
        } catch (_) {
          return _localFollows
              .where((id) => id.startsWith('${userId}_'))
              .length;
        }
      }
    }

    return _localFollows.where((id) => id.startsWith('${userId}_')).length;
  }

  /// Fetch full user profile from Firestore `users/{userId}`
  Future<UserModel?> getUserProfile(String userId) async {
    if (userId.isEmpty) return null;

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final doc = await FirebaseService.firestore!
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, docId: doc.id);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Search real users from Firestore by display name, email, handle or UID
  Future<List<UserModel>> searchUsers(String query) async {
    final rawQ = query.trim().toLowerCase();
    final cleanQ = rawQ.startsWith('@') ? rawQ.substring(1) : rawQ;
    if (cleanQ.isEmpty) return [];

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final snap = await FirebaseService.firestore!
            .collection('users')
            .limit(50)
            .get();

        return snap.docs
            .map((d) => UserModel.fromMap(d.data(), docId: d.id))
            .where((u) {
              final name = u.displayName.toLowerCase();
              final email = u.email.toLowerCase();
              final handle = email.contains('@') ? email.split('@').first : email;
              final uid = u.uid.toLowerCase();
              return name.contains(cleanQ) ||
                  email.contains(cleanQ) ||
                  handle.contains(cleanQ) ||
                  uid == cleanQ ||
                  uid.contains(cleanQ);
            })
            .toList();
      } catch (_) {}
    }

    return [];
  }

  /// Fetch real stories published by [userId]
  Future<List<StoryModel>> getUserStories(String userId, {bool includeDrafts = false}) async {
    if (userId.isEmpty) return [];

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        Query query = FirebaseService.firestore!
            .collection('stories')
            .where('creatorId', isEqualTo: userId);

        if (!includeDrafts) {
          query = query.where('isPublished', isEqualTo: true);
        }

        final snap = await query.limit(30).get();
        return snap.docs.map((d) {
          return StoryModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id);
        }).toList();
      } catch (_) {}
    }

    return [];
  }
}

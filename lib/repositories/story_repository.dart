import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../models/story_node_model.dart';
import '../models/story_ending_model.dart';
import '../models/story_play_model.dart';
import '../models/user_choice_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import 'sample_data.dart';

class StoryRepository {
  final StorageService _storageService;
  final bool? enableSampleFallback;

  bool get _shouldUseSampleFallback =>
      enableSampleFallback ?? (!FirebaseService.isFirebaseReady);

  // In-memory runtime cache for seamless offline and immediate responsiveness
  List<StoryModel> _stories = [];
  final Map<String, Map<String, StoryNodeModel>> _storyNodesMap = {};
  final Map<String, Map<String, StoryEndingModel>> _storyEndingsMap = {};
  final Map<String, List<CommentModel>> _commentsMap = {};
  final Map<String, Timer> _likeDebounceTimers = {};

  StoryRepository(
    this._storageService, {
    this.enableSampleFallback,
  }) {
    if (_shouldUseSampleFallback) {
      _initSampleData();
    }
  }

  void _initSampleData() {
    _stories = SampleData.getStories();
    _storyNodesMap['story_one_last_message'] = SampleData.getOneLastMessageNodes();
    _storyEndingsMap['story_one_last_message'] = SampleData.getOneLastMessageEndings();
    _commentsMap['story_one_last_message'] = SampleData.getSampleComments('story_one_last_message');
  }

  Future<List<StoryModel>> getStories({
    String tab = 'For You',
    String? category,
    String? searchQuery,
    DocumentSnapshot? startAfterDoc,
    int limit = 20,
  }) async {
    // Cursor-based Firestore query with limit(20) when online
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        Query query = FirebaseService.firestore!
            .collection('stories')
            .where('isPublished', isEqualTo: true)
            .limit(limit);

        if (startAfterDoc != null) {
          query = query.startAfterDocument(startAfterDoc);
        }

        final snap = await query.get();
        final remoteStories = snap.docs.map((d) {
          return StoryModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id);
        }).toList();

        if (startAfterDoc == null) {
          _stories = remoteStories;
        } else {
          for (final s in remoteStories) {
            final idx = _stories.indexWhere((existing) => existing.id == s.id);
            if (idx == -1) {
              _stories.add(s);
            } else {
              _stories[idx] = s;
            }
          }
        }
      } catch (_) {
        // Preserve offline in-memory cache if query fails
      }
    } else if (_shouldUseSampleFallback && _stories.isEmpty) {
      _stories = SampleData.getStories();
    }

    // Sync isSaved and isLiked from storage
    final savedIds = _storageService.getSavedStoryIds();
    final likedIds = _storageService.getLikedStoryIds();

    var list = _stories.map((story) {
      return story.copyWith(
        isSaved: savedIds.contains(story.id),
        isLiked: likedIds.contains(story.id),
      );
    }).toList();

    // Category filter
    if (category != null && category != 'All' && category.isNotEmpty) {
      list = list.where((s) {
        return s.category.toLowerCase() == category.toLowerCase() ||
            s.categories.any((c) => c.toLowerCase() == category.toLowerCase());
      }).toList();
    }

    // Search query filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      list = list.where((s) {
        return s.title.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query) ||
            s.creatorName.toLowerCase().contains(query);
      }).toList();
    }

    // Feed tabs
    if (tab == 'Trending') {
      list.sort((a, b) => b.plays.compareTo(a.plays));
    } else if (tab == 'Following') {
      list = list.where((s) => s.isFollowingCreator || s.creatorId == 'creator_kavin').toList();
    }

    return list.take(limit).toList();
  }

  Future<StoryModel?> getStoryById(String storyId) async {
    final cached = _stories.where((s) => s.id == storyId);
    if (cached.isNotEmpty) return cached.first;

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final doc = await FirebaseService.firestore!
            .collection('stories')
            .doc(storyId)
            .get();
        if (doc.exists && doc.data() != null) {
          final story = StoryModel.fromMap(doc.data()!, docId: doc.id);
          final idx = _stories.indexWhere((s) => s.id == story.id);
          if (idx == -1) {
            _stories.add(story);
          } else {
            _stories[idx] = story;
          }
          return story;
        }
      } catch (_) {}
    }

    if (_shouldUseSampleFallback) {
      final fallbackStories = SampleData.getStories().where((s) => s.id == storyId);
      if (fallbackStories.isNotEmpty) return fallbackStories.first;
    }

    return null;
  }

  Future<StoryNodeModel?> getStoryNode(String storyId, String nodeId) async {
    // 1. Try memory map
    if (_storyNodesMap.containsKey(storyId) && _storyNodesMap[storyId]!.containsKey(nodeId)) {
      return _storyNodesMap[storyId]![nodeId];
    }

    // 2. Try Firestore if ready
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final doc = await FirebaseService.firestore!
            .collection('stories')
            .doc(storyId)
            .collection('nodes')
            .doc(nodeId)
            .get();
        if (doc.exists && doc.data() != null) {
          final node = StoryNodeModel.fromMap(doc.data()!, docId: doc.id);
          _storyNodesMap.putIfAbsent(storyId, () => {})[nodeId] = node;
          return node;
        }
      } catch (_) {}
    }

    // Fallback for default demo/tests only if fallback is enabled
    if (_shouldUseSampleFallback) {
      final fallback = _storyNodesMap['story_one_last_message']?[nodeId];
      if (fallback != null) {
        _storyNodesMap.putIfAbsent(storyId, () => {})[nodeId] = fallback;
      }
      return fallback;
    }

    return null;
  }

  Future<List<StoryEndingModel>> getStoryEndings(String storyId) async {
    if (_storyEndingsMap.containsKey(storyId) && _storyEndingsMap[storyId]!.isNotEmpty) {
      return _storyEndingsMap[storyId]!.values.toList();
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final snap = await FirebaseService.firestore!
            .collection('endings')
            .where('storyId', isEqualTo: storyId)
            .get();
        if (snap.docs.isNotEmpty) {
          final endings = snap.docs.map((d) => StoryEndingModel.fromMap(d.data(), docId: d.id)).toList();
          final map = _storyEndingsMap.putIfAbsent(storyId, () => {});
          for (final e in endings) {
            map[e.id] = e;
          }
          return endings;
        }
      } catch (_) {}
    }

    if (_shouldUseSampleFallback) {
      final fallback = _storyEndingsMap['story_one_last_message']?.values.toList() ?? [];
      if (fallback.isNotEmpty) {
        final map = _storyEndingsMap.putIfAbsent(storyId, () => {});
        for (final e in fallback) {
          map[e.id] = e;
        }
      }
      return fallback;
    }

    return [];
  }

  Future<StoryEndingModel?> getEndingById(String storyId, String endingId) async {
    if (_storyEndingsMap.containsKey(storyId) && _storyEndingsMap[storyId]!.containsKey(endingId)) {
      return _storyEndingsMap[storyId]![endingId];
    }
    final endings = await getStoryEndings(storyId);
    final match = endings.where((e) => e.id == endingId);
    if (match.isNotEmpty) {
      _storyEndingsMap.putIfAbsent(storyId, () => {})[endingId] = match.first;
      return match.first;
    }
    return null;
  }

  Set<String> getUnlockedEndingIds(String storyId) {
    return _storageService.getUnlockedEndingIds(storyId);
  }

  Future<void> recordUserChoice(UserChoiceModel choice) async {
    await _storageService.incrementChoicesMadeCount();
    // Stop per-choice Firestore writes: choices are stored locally in memory
    // and full choice history is persisted with the final play session.
  }

  Future<void> recordStoryPlay(StoryPlayModel play) async {
    await _storageService.recordStoryPlayed(play.storyId);
    if (play.endingId != null) {
      await _storageService.recordUnlockedEnding(play.storyId, play.endingId!);
    }

    // Optimistically update play count
    final index = _stories.indexWhere((s) => s.id == play.storyId);
    if (index != -1) {
      _stories[index] = _stories[index].copyWith(plays: _stories[index].plays + 1);
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        await FirebaseService.firestore!
            .collection('storyPlays')
            .doc(play.id)
            .set(play.toMap());
      } catch (_) {}
    }
  }

  Future<bool> toggleLikeStory(String storyId, String userId) async {
    await _storageService.toggleLikedStory(storyId);
    final isLiked = _storageService.isStoryLiked(storyId);

    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final current = _stories[index];
      _stories[index] = current.copyWith(
        isLiked: isLiked,
        likes: isLiked ? current.likes + 1 : current.likes - 1,
      );
    }

    // Debounce rapid like toggles (~400ms) to coalesce rapid taps into a single settled write
    final debounceKey = '${userId}_$storyId';
    _likeDebounceTimers[debounceKey]?.cancel();
    _likeDebounceTimers[debounceKey] = Timer(const Duration(milliseconds: 400), () async {
      _likeDebounceTimers.remove(debounceKey);
      if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
        try {
          final currentlyLiked = _storageService.isStoryLiked(storyId);
          final likeDocRef = FirebaseService.firestore!.collection('likes').doc(debounceKey);
          if (currentlyLiked) {
            await likeDocRef.set({
              'userId': userId,
              'storyId': storyId,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            await likeDocRef.delete();
          }
        } catch (_) {}
      }
    });

    return isLiked;
  }

  Future<bool> toggleSaveStory(String storyId) async {
    await _storageService.toggleSavedStory(storyId);
    final isSaved = _storageService.isStorySaved(storyId);

    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      _stories[index] = _stories[index].copyWith(isSaved: isSaved);
    }

    return isSaved;
  }

  bool isStorySaved(String storyId) => _storageService.isStorySaved(storyId);
  bool isStoryLiked(String storyId) => _storageService.isStoryLiked(storyId);

  Future<List<StoryModel>> getSavedStories() async {
    final savedIds = _storageService.getSavedStoryIds();
    if (savedIds.isEmpty) return [];
    final all = await getStories();
    final results = all.where((s) => savedIds.contains(s.id)).toList();
    for (final id in savedIds) {
      if (!results.any((s) => s.id == id)) {
        final story = await getStoryById(id);
        if (story != null) results.add(story);
      }
    }
    return results;
  }

  Future<List<StoryModel>> getHistoryStories() async {
    final historyIds = _storageService.getHistoryStoryIds();
    if (historyIds.isEmpty) return [];
    final all = await getStories();
    final results = <StoryModel>[];
    for (var id in historyIds) {
      final match = all.where((s) => s.id == id);
      if (match.isNotEmpty) {
        results.add(match.first);
      } else {
        final story = await getStoryById(id);
        if (story != null) results.add(story);
      }
    }
    return results;
  }

  Future<List<CommentModel>> getComments(
    String storyId, {
    DocumentSnapshot? startAfterDoc,
    int limit = 20,
  }) async {
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        Query query = FirebaseService.firestore!
            .collection('comments')
            .where('storyId', isEqualTo: storyId)
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (startAfterDoc != null) {
          query = query.startAfterDocument(startAfterDoc);
        }

        final snap = await query.get();
        if (snap.docs.isNotEmpty) {
          final remoteComments = snap.docs.map((d) {
            return CommentModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id);
          }).toList();

          final cache = _commentsMap.putIfAbsent(storyId, () => []);
          for (final c in remoteComments) {
            if (!cache.any((existing) => existing.id == c.id)) {
              cache.add(c);
            }
          }
          return remoteComments;
        }
      } catch (_) {}
    }

    if (_commentsMap.containsKey(storyId)) {
      return _commentsMap[storyId]!.take(limit).toList();
    }
    return [];
  }

  Future<CommentModel> addComment(String storyId, String text, UserModel user) async {
    final newComment = CommentModel(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      storyId: storyId,
      userId: user.uid,
      userName: user.displayName,
      userAvatar: user.photoUrl,
      text: text,
      likes: 0,
      createdAt: DateTime.now(),
    );

    if (!_commentsMap.containsKey(storyId)) {
      _commentsMap[storyId] = [];
    }
    _commentsMap[storyId]!.insert(0, newComment);

    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      _stories[index] = _stories[index].copyWith(
        commentsCount: _stories[index].commentsCount + 1,
      );
    }

    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        await FirebaseService.firestore!
            .collection('comments')
            .doc(newComment.id)
            .set(newComment.toMap());
      } catch (_) {}
    }

    return newComment;
  }

  void cacheStoryNodes(String storyId, Map<String, StoryNodeModel> nodes) {
    _storyNodesMap[storyId] = Map.from(nodes);
  }

  void cacheStoryEndings(String storyId, List<StoryEndingModel> endings) {
    final map = _storyEndingsMap.putIfAbsent(storyId, () => {});
    for (final e in endings) {
      map[e.id] = e;
    }
  }

  Future<bool> publishStory({
    required StoryModel story,
    required List<StoryNodeModel> nodes,
    required List<StoryEndingModel> endings,
  }) async {
    // 1. Immediately cache in memory for instantaneous local responsiveness
    final nodeMap = {for (final n in nodes) n.nodeId: n};
    _storyNodesMap[story.id] = nodeMap;

    final endingMap = _storyEndingsMap.putIfAbsent(story.id, () => {});
    for (final e in endings) {
      endingMap[e.id] = e;
    }

    final existingIdx = _stories.indexWhere((s) => s.id == story.id);
    if (existingIdx != -1) {
      _stories[existingIdx] = story;
    } else {
      _stories.insert(0, story);
    }

    // 2. Persist to Firestore if online
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final firestore = FirebaseService.firestore!;
        final storyRef = firestore.collection('stories').doc(story.id);

        final storyMap = {
          'id': story.id,
          'title': story.titleMap,
          'description': story.descriptionMap,
          'availableLanguages': story.availableLanguages,
          'coverUrl': story.coverUrl,
          'category': story.category,
          'categories': story.categories.isNotEmpty ? story.categories : [story.category],
          'creatorId': story.creatorId,
          'creatorName': story.creatorName,
          'creatorAvatar': story.creatorAvatar,
          'duration': story.duration,
          'plays': 0,
          'likes': 0,
          'commentsCount': 0,
          'endingsCount': endings.length,
          'startNodeId': story.startNodeId,
          'isPublished': true,
          'isDraft': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Step 1: Commit parent story doc first so isStoryCreator security check succeeds
        await storyRef.set(storyMap);

        // Step 2: Batch commit nodes subcollection and endings collection
        final batch = firestore.batch();

        for (final node in nodes) {
          final nodeRef = storyRef.collection('nodes').doc(node.nodeId);
          batch.set(nodeRef, node.toMap());
        }

        for (final ending in endings) {
          final endingRef = firestore.collection('endings').doc(ending.id);
          batch.set(endingRef, ending.toMap());
        }

        await batch.commit();
        return true;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  void dispose() {
    for (final timer in _likeDebounceTimers.values) {
      timer.cancel();
    }
    _likeDebounceTimers.clear();
  }
}

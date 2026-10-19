import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../repositories/story_repository.dart';
import '../repositories/social_repository.dart';
import '../core/services/storage_service.dart';
import '../core/services/firebase_service.dart';

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

class ProfileProvider extends ChangeNotifier {
  final StoryRepository _storyRepository;
  final StorageService _storageService;
  final SocialRepository _socialRepository;

  List<StoryModel> _savedStories = [];
  List<StoryModel> _historyStories = [];
  List<StoryModel> _myStories = [];
  List<AchievementBadge> _achievements = [];
  bool _isLoading = false;

  int _storiesPlayedCount = 0;
  int _endingsFoundCount = 0;
  int _choicesMadeCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  List<StoryModel> get savedStories => _savedStories;
  List<StoryModel> get historyStories => _historyStories;
  List<StoryModel> get myStories => _myStories;
  List<AchievementBadge> get achievements => _achievements;
  bool get isLoading => _isLoading;

  int get storiesPlayedCount => _storiesPlayedCount;
  int get endingsFoundCount => _endingsFoundCount;
  int get choicesMadeCount => _choicesMadeCount;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;

  ProfileProvider(
    this._storyRepository,
    this._storageService, {
    SocialRepository? socialRepository,
  }) : _socialRepository = socialRepository ?? SocialRepository(_storageService) {
    loadProfileData();
  }

  Future<void> loadProfileData([String? userId]) async {
    _isLoading = true;
    notifyListeners();

    final currentUid = userId ??
        FirebaseService.auth?.currentUser?.uid ??
        _storageService.getCachedUserProfile()?['uid'] as String?;

    try {
      _savedStories = await _storyRepository.getSavedStories();
      _historyStories = await _storyRepository.getHistoryStories();

      if (currentUid != null && currentUid.isNotEmpty) {
        // Real user stories from Firestore
        _myStories = await _socialRepository.getUserStories(currentUid, includeDrafts: true);
        // Real live followers & following from Firestore
        _followersCount = await _socialRepository.getFollowersCount(currentUid);
        _followingCount = await _socialRepository.getFollowingCount(currentUid);
      } else {
        _myStories = [];
        _followersCount = 0;
        _followingCount = 0;
      }

      _storiesPlayedCount = _historyStories.length;
      _endingsFoundCount = _storageService.getTotalEndingsUnlockedCount();
      _choicesMadeCount = _storageService.getChoicesMadeCount();

      _achievements = [
        AchievementBadge(
          id: 'ach_first_choice',
          title: 'First Choice',
          description: 'Made your first interactive story decision',
          icon: '⚡',
          isUnlocked: _choicesMadeCount >= 1,
        ),
        AchievementBadge(
          id: 'ach_secret_hunter',
          title: 'Secret Hunter',
          description: 'Discovered a rare Secret Ending in a story',
          icon: '👑',
          isUnlocked: _endingsFoundCount >= 1,
        ),
        AchievementBadge(
          id: 'ach_pathfinder',
          title: 'Pathfinder',
          description: 'Played 5 or more distinct branching storylines',
          icon: '🧭',
          isUnlocked: _storiesPlayedCount >= 5,
        ),
        AchievementBadge(
          id: 'ach_night_owl',
          title: 'Midnight Voyager',
          description: 'Played a mystery story past midnight',
          icon: '🌙',
          isUnlocked: false,
        ),
        AchievementBadge(
          id: 'ach_storyteller',
          title: 'Master of Fates',
          description: 'Discovered all endings in a single story',
          icon: '🔮',
          isUnlocked: false,
        ),
      ];
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> followUser(String targetUserId, {UserModel? currentUser}) async {
    final success = await _socialRepository.followUser(targetUserId, currentUser: currentUser);
    if (success) {
      final currentUid = currentUser?.uid ?? FirebaseService.auth?.currentUser?.uid;
      if (currentUid != null) {
        _followingCount = await _socialRepository.getFollowingCount(currentUid);
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> unfollowUser(String targetUserId, {String? currentUserId}) async {
    final uid = currentUserId ?? FirebaseService.auth?.currentUser?.uid;
    final success = await _socialRepository.unfollowUser(targetUserId, currentUserId: uid);
    if (success) {
      if (uid != null) {
        _followingCount = await _socialRepository.getFollowingCount(uid);
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> isFollowing(String targetUserId, {String? currentUserId}) =>
      _socialRepository.isFollowing(
        targetUserId,
        currentUserId: currentUserId ?? FirebaseService.auth?.currentUser?.uid,
      );

  Future<int> getFollowersCount(String userId) =>
      _socialRepository.getFollowersCount(userId);

  Future<int> getFollowingCount(String userId) =>
      _socialRepository.getFollowingCount(userId);

  Future<UserModel?> getUserProfile(String userId) =>
      _socialRepository.getUserProfile(userId);

  Future<List<UserModel>> searchUsers(String query) =>
      _socialRepository.searchUsers(query);

  Future<List<StoryModel>> getUserStories(String userId) =>
      _socialRepository.getUserStories(userId);
}

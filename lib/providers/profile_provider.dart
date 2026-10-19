import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import '../core/services/storage_service.dart';

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

  List<StoryModel> _savedStories = [];
  List<StoryModel> _historyStories = [];
  List<AchievementBadge> _achievements = [];
  bool _isLoading = false;

  int _storiesPlayedCount = 0;
  int _endingsFoundCount = 0;
  int _choicesMadeCount = 0;

  List<StoryModel> get savedStories => _savedStories;
  List<StoryModel> get historyStories => _historyStories;
  List<AchievementBadge> get achievements => _achievements;
  bool get isLoading => _isLoading;

  int get storiesPlayedCount => _storiesPlayedCount;
  int get endingsFoundCount => _endingsFoundCount;
  int get choicesMadeCount => _choicesMadeCount;

  ProfileProvider(this._storyRepository, this._storageService) {
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedStories = await _storyRepository.getSavedStories();
      _historyStories = await _storyRepository.getHistoryStories();

      _storiesPlayedCount = _historyStories.isNotEmpty ? _historyStories.length + 3 : 4;
      _endingsFoundCount = _storageService.getTotalEndingsUnlockedCount() + 3;
      _choicesMadeCount = _storageService.getChoicesMadeCount() + 18;

      _achievements = [
        AchievementBadge(
          id: 'ach_first_choice',
          title: 'First Choice',
          description: 'Made your first interactive story decision',
          icon: '⚡',
          isUnlocked: true,
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
          isUnlocked: true,
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
}

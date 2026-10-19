import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import '../core/services/analytics_service.dart';

class StoryFeedProvider extends ChangeNotifier {
  final StoryRepository _storyRepository;
  final AnalyticsService _analyticsService;

  List<StoryModel> _stories = [];
  bool _isLoading = false;
  String _currentTab = 'For You';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<StoryModel> get stories => _stories;
  bool get isLoading => _isLoading;
  String get currentTab => _currentTab;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  StoryFeedProvider(this._storyRepository, this._analyticsService) {
    loadStories();
  }

  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stories = await _storyRepository.getStories(
        tab: _currentTab,
        category: _selectedCategory,
        searchQuery: _searchQuery,
      );
    } catch (_) {
      _stories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTab(String tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    loadStories();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadStories();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadStories();
  }

  Future<void> toggleLike(String storyId, String userId) async {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final current = _stories[index];
      final newLiked = !current.isLiked;
      _stories[index] = current.copyWith(
        isLiked: newLiked,
        likes: newLiked ? current.likes + 1 : current.likes - 1,
      );
      notifyListeners();
    }

    final result = await _storyRepository.toggleLikeStory(storyId, userId);

    // Track analytics if liked
    if (result) {
      _analyticsService.logStorySaved(storyId: storyId, isSaved: true);
    }
  }

  Future<void> toggleSave(String storyId) async {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final current = _stories[index];
      final newSaved = !current.isSaved;
      _stories[index] = current.copyWith(isSaved: newSaved);
      notifyListeners();

      _analyticsService.logStorySaved(storyId: storyId, isSaved: newSaved);
    }

    await _storyRepository.toggleSaveStory(storyId);
  }
}

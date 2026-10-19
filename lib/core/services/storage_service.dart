import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keySavedStories = 'twist_saved_stories';
  static const String _keyLikedStories = 'twist_liked_stories';
  static const String _keyUnlockedEndings = 'twist_unlocked_endings';
  static const String _keyPlayHistory = 'twist_play_history';
  static const String _keyUserChoices = 'twist_user_choices';
  static const String _keyUserProfile = 'twist_user_profile';
  static const String _keySelectedLanguage = 'twist_selected_language';
  static const String _keyInitialLanguageSelected = 'twist_initial_language_selected';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Language settings
  String? getSavedLanguageCode() {
    return _prefs.getString(_keySelectedLanguage);
  }

  Future<void> saveLanguageCode(String code) async {
    await _prefs.setString(_keySelectedLanguage, code);
  }

  bool hasSelectedInitialLanguage() {
    return _prefs.getBool(_keyInitialLanguageSelected) ?? false;
  }

  Future<void> setInitialLanguageSelected(bool selected) async {
    await _prefs.setBool(_keyInitialLanguageSelected, selected);
  }

  // Saved stories
  Set<String> getSavedStoryIds() {
    return _prefs.getStringList(_keySavedStories)?.toSet() ?? {};
  }

  Future<void> toggleSavedStory(String storyId) async {
    final list = getSavedStoryIds();
    if (list.contains(storyId)) {
      list.remove(storyId);
    } else {
      list.add(storyId);
    }
    await _prefs.setStringList(_keySavedStories, list.toList());
  }

  bool isStorySaved(String storyId) {
    return getSavedStoryIds().contains(storyId);
  }

  // Liked stories
  Set<String> getLikedStoryIds() {
    return _prefs.getStringList(_keyLikedStories)?.toSet() ?? {};
  }

  Future<void> toggleLikedStory(String storyId) async {
    final list = getLikedStoryIds();
    if (list.contains(storyId)) {
      list.remove(storyId);
    } else {
      list.add(storyId);
    }
    await _prefs.setStringList(_keyLikedStories, list.toList());
  }

  bool isStoryLiked(String storyId) {
    return getLikedStoryIds().contains(storyId);
  }

  // Unlocked endings (Map: storyId -> Set of endingIds)
  Set<String> getUnlockedEndingIds(String storyId) {
    final raw = _prefs.getStringList('${_keyUnlockedEndings}_$storyId');
    return raw?.toSet() ?? {};
  }

  Future<void> recordUnlockedEnding(String storyId, String endingId) async {
    final endings = getUnlockedEndingIds(storyId);
    endings.add(endingId);
    await _prefs.setStringList('${_keyUnlockedEndings}_$storyId', endings.toList());
  }

  int getTotalEndingsUnlockedCount() {
    int total = 0;
    final keys = _prefs.getKeys();
    for (var k in keys) {
      if (k.startsWith(_keyUnlockedEndings)) {
        total += (_prefs.getStringList(k)?.length ?? 0);
      }
    }
    return total;
  }

  // Played history (storyId -> last played timestamp)
  List<String> getHistoryStoryIds() {
    return _prefs.getStringList(_keyPlayHistory) ?? [];
  }

  Future<void> recordStoryPlayed(String storyId) async {
    final history = getHistoryStoryIds();
    history.remove(storyId);
    history.insert(0, storyId);
    if (history.length > 50) history.removeLast();
    await _prefs.setStringList(_keyPlayHistory, history);
  }

  // Recorded choices count
  int getChoicesMadeCount() {
    return _prefs.getInt(_keyUserChoices) ?? 0;
  }

  Future<void> incrementChoicesMadeCount() async {
    final current = getChoicesMadeCount();
    await _prefs.setInt(_keyUserChoices, current + 1);
  }

  // User Profile
  Map<String, dynamic>? getCachedUserProfile() {
    final str = _prefs.getString(_keyUserProfile);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUserProfile(Map<String, dynamic> data) async {
    await _prefs.setString(_keyUserProfile, jsonEncode(data));
  }

  // User Activities Cache
  static const String _keyUserActivities = 'twist_user_activities';

  List<Map<String, dynamic>>? getCachedActivities(String userId) {
    final str = _prefs.getString('${_keyUserActivities}_$userId');
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheActivities(String userId, List<Map<String, dynamic>> activities) async {
    await _prefs.setString('${_keyUserActivities}_$userId', jsonEncode(activities));
  }

  Future<void> clearUserActivities([String? userId]) async {
    if (userId != null && userId.isNotEmpty) {
      await _prefs.remove('${_keyUserActivities}_$userId');
    } else {
      for (final key in _prefs.getKeys()) {
        if (key.startsWith(_keyUserActivities) || key.contains('activity')) {
          await _prefs.remove(key);
        }
      }
    }
    // Also remove legacy unnamespaced activity cache
    await _prefs.remove(_keyUserActivities);
    await _prefs.remove('twist_activities');
  }

  Future<void> clearStaleActivityData({String? currentUserId}) async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key == _keyUserActivities || key == 'twist_activities') {
        await _prefs.remove(key);
      } else if (key.startsWith('${_keyUserActivities}_')) {
        if (currentUserId == null || key != '${_keyUserActivities}_$currentUserId') {
          await _prefs.remove(key);
        }
      }
    }
  }
}

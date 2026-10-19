import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics? _firebaseAnalytics;

  AnalyticsService([this._firebaseAnalytics]);

  Future<void> logAppOpen() async {
    _log('app_open', {});
    try {
      await _firebaseAnalytics?.logAppOpen();
    } catch (_) {}
  }

  Future<void> logStoryView({
    required String storyId,
    required String storyTitle,
    required String category,
  }) async {
    final params = {
      'story_id': storyId,
      'story_title': storyTitle,
      'category': category,
    };
    _log('story_view', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_view',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logStoryStart({
    required String storyId,
    required String storyTitle,
  }) async {
    final params = {
      'story_id': storyId,
      'story_title': storyTitle,
    };
    _log('story_start', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_start',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logChoiceSelected({
    required String storyId,
    required String nodeId,
    required String choiceId,
    required String choiceLabel,
    int? sceneNumber,
  }) async {
    final params = {
      'story_id': storyId,
      'node_id': nodeId,
      'choice_id': choiceId,
      'choice_label': choiceLabel,
      'scene_number': sceneNumber ?? 0,
    };
    _log('choice_selected', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'choice_selected',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logStoryCompleted({
    required String storyId,
    required String endingId,
    required int choicesCount,
  }) async {
    final params = {
      'story_id': storyId,
      'ending_id': endingId,
      'choices_count': choicesCount,
    };
    _log('story_completed', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_completed',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logEndingUnlocked({
    required String storyId,
    required String endingId,
    required String endingTitle,
    required String rarity,
    required bool isSecret,
  }) async {
    final params = {
      'story_id': storyId,
      'ending_id': endingId,
      'ending_title': endingTitle,
      'rarity': rarity,
      'is_secret': isSecret,
    };
    _log('ending_unlocked', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'ending_unlocked',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logStoryReplay({
    required String storyId,
  }) async {
    final params = {'story_id': storyId};
    _log('story_replay', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_replay',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logStoryShared({
    required String storyId,
    String? endingId,
    required String sharePlatform,
  }) async {
    final params = {
      'story_id': storyId,
      'ending_id': endingId ?? 'none',
      'platform': sharePlatform,
    };
    _log('story_shared', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_shared',
        parameters: params,
      );
    } catch (_) {}
  }

  Future<void> logStorySaved({
    required String storyId,
    required bool isSaved,
  }) async {
    final params = {
      'story_id': storyId,
      'is_saved': isSaved,
    };
    _log('story_saved', params);
    try {
      await _firebaseAnalytics?.logEvent(
        name: 'story_saved',
        parameters: params,
      );
    } catch (_) {}
  }

  void _log(String event, Map<String, dynamic> params) {
    dev.log('📊 [Analytics] $event: $params', name: 'TwistAnalytics');
  }
}

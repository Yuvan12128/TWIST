import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _activityRepository;
  final StorageService? storageService;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  String? _currentUserId;
  StreamSubscription? _authSubscription;

  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  int get unreadCount => _activityRepository.getUnreadCount();

  ActivityProvider(
    this._activityRepository, {
    this.storageService,
  }) {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      _authSubscription = FirebaseService.auth!.authStateChanges().listen((user) {
        if (user == null) {
          clearForLogout();
        } else if (user.uid != _currentUserId) {
          _activities = [];
          _activityRepository.clearCache();
          _currentUserId = user.uid;
          notifyListeners();
          loadActivities(userId: user.uid);
        }
      });
    }
    loadActivities();
  }

  String? _resolveCurrentUserId() {
    if (FirebaseService.isFirebaseReady && FirebaseService.auth != null) {
      final uid = FirebaseService.auth!.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    }
    return storageService?.getCachedUserProfile()?['uid'] as String?;
  }

  Future<void> loadActivities({String? userId, bool forceRefresh = false}) async {
    final uid = userId ?? _resolveCurrentUserId();

    // If no user is logged in
    if (uid == null || uid.isEmpty) {
      if (!_activityRepository.shouldUseSampleFallback) {
        _activities = [];
        _currentUserId = null;
        _activityRepository.clearCache();
        notifyListeners();
        return;
      }
    }

    // If logged-in user changed from previous user, immediately wipe in-memory list
    if (_currentUserId != null && _currentUserId != uid) {
      _activities = [];
      _activityRepository.clearCache();
      notifyListeners();
    }
    _currentUserId = uid;

    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _activityRepository.getActivities(
        userId: uid,
        filter: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      _activities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    loadActivities();
  }

  Future<void> markAsRead(String id) async {
    final uid = _currentUserId ?? _resolveCurrentUserId();
    await _activityRepository.markAsRead(id, userId: uid);
    final index = _activities.indexWhere((a) => a.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _currentUserId ?? _resolveCurrentUserId();
    await _activityRepository.markAllAsRead(userId: uid);
    _activities = _activities.map((a) => a.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> clearForLogout([String? userId]) async {
    final uid = userId ?? _currentUserId ?? _resolveCurrentUserId();
    _activities = [];
    _currentUserId = null;
    await _activityRepository.clearUserActivities(uid);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

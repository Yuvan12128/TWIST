import '../core/localization/app_language.dart';

class StoryModel {
  final String id;
  final Map<String, String> titleMap;
  final Map<String, String> descriptionMap;
  final List<String> availableLanguages;
  final String coverUrl;
  final String category;
  final List<String> categories;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;
  final String duration;
  final int plays;
  final int likes;
  final int commentsCount;
  final int endingsCount;
  final String startNodeId;
  final bool isSaved;
  final bool isLiked;
  final bool isFollowingCreator;
  final DateTime createdAt;

  const StoryModel({
    required this.id,
    required this.titleMap,
    required this.descriptionMap,
    this.availableLanguages = const ['en', 'ta', 'tanglish'],
    required this.coverUrl,
    required this.category,
    this.categories = const [],
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar,
    required this.duration,
    this.plays = 0,
    this.likes = 0,
    this.commentsCount = 0,
    this.endingsCount = 4,
    this.startNodeId = 'node_start',
    this.isSaved = false,
    this.isLiked = false,
    this.isFollowingCreator = false,
    required this.createdAt,
  });

  // Backward compatibility getters
  String get title => localizedTitle(AppLanguage.en);
  String get description => localizedDescription(AppLanguage.en);

  String localizedTitle(AppLanguage language) {
    final text = AppLanguage.getLocalizedText(titleMap, language);
    return text.isNotEmpty ? text : (titleMap['en'] ?? '');
  }

  String localizedDescription(AppLanguage language) {
    final text = AppLanguage.getLocalizedText(descriptionMap, language);
    return text.isNotEmpty ? text : (descriptionMap['en'] ?? '');
  }

  StoryModel copyWith({
    Map<String, String>? titleMap,
    Map<String, String>? descriptionMap,
    List<String>? availableLanguages,
    String? coverUrl,
    String? category,
    List<String>? categories,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    String? duration,
    int? plays,
    int? likes,
    int? commentsCount,
    int? endingsCount,
    String? startNodeId,
    bool? isSaved,
    bool? isLiked,
    bool? isFollowingCreator,
    DateTime? createdAt,
  }) {
    return StoryModel(
      id: id,
      titleMap: titleMap ?? this.titleMap,
      descriptionMap: descriptionMap ?? this.descriptionMap,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      duration: duration ?? this.duration,
      plays: plays ?? this.plays,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      endingsCount: endingsCount ?? this.endingsCount,
      startNodeId: startNodeId ?? this.startNodeId,
      isSaved: isSaved ?? this.isSaved,
      isLiked: isLiked ?? this.isLiked,
      isFollowingCreator: isFollowingCreator ?? this.isFollowingCreator,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': titleMap,
      'description': descriptionMap,
      'availableLanguages': availableLanguages,
      'coverUrl': coverUrl,
      'category': category,
      'categories': categories,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorAvatar': creatorAvatar,
      'duration': duration,
      'plays': plays,
      'likes': likes,
      'commentsCount': commentsCount,
      'endingsCount': endingsCount,
      'startNodeId': startNodeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Parse title map (supports both legacy string and multilingual map)
    Map<String, String> parsedTitle = {};
    if (map['title'] is Map) {
      parsedTitle = (map['title'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else if (map['title'] is String) {
      parsedTitle = {'en': map['title'] as String};
    }

    // Parse description map
    Map<String, String> parsedDesc = {};
    if (map['description'] is Map) {
      parsedDesc = (map['description'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else if (map['description'] is String) {
      parsedDesc = {'en': map['description'] as String};
    }

    final rawCats = map['categories'];
    List<String> cats = [];
    if (rawCats is List) {
      cats = rawCats.map((e) => e.toString()).toList();
    } else if (map['category'] != null) {
      cats = [map['category'].toString()];
    }

    final rawLangs = map['availableLanguages'];
    List<String> langs = ['en', 'ta', 'tanglish'];
    if (rawLangs is List) {
      langs = rawLangs.map((e) => e.toString()).toList();
    }

    return StoryModel(
      id: docId ?? map['id'] as String? ?? '',
      titleMap: parsedTitle,
      descriptionMap: parsedDesc,
      availableLanguages: langs,
      coverUrl: map['coverUrl'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      categories: cats,
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'TWIST Creator',
      creatorAvatar: map['creatorAvatar'] as String?,
      duration: map['duration'] as String? ?? '5 min',
      plays: (map['plays'] as num?)?.toInt() ?? 0,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      endingsCount: (map['endingsCount'] as num?)?.toInt() ?? 4,
      startNodeId: map['startNodeId'] as String? ?? 'node_start',
      isSaved: map['isSaved'] as bool? ?? false,
      isLiked: map['isLiked'] as bool? ?? false,
      isFollowingCreator: map['isFollowingCreator'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

import '../core/localization/app_language.dart';

class StoryEndingModel {
  final String id;
  final String storyId;
  final Map<String, String> titleMap;
  final Map<String, String> descriptionMap;
  final String imageUrl;
  final String rarity; // 'Common', 'Uncommon', 'Rare', 'Secret'
  final double rarityPercentage;
  final bool isSecret;
  final String? badgeIcon;

  const StoryEndingModel({
    required this.id,
    required this.storyId,
    required this.titleMap,
    required this.descriptionMap,
    required this.imageUrl,
    this.rarity = 'Common',
    this.rarityPercentage = 25.0,
    this.isSecret = false,
    this.badgeIcon,
  });

  String get title => localizedTitle(AppLanguage.en);
  String get description => localizedDescription(AppLanguage.en);

  String localizedTitle(AppLanguage language) {
    final t = AppLanguage.getLocalizedText(titleMap, language);
    return t.isNotEmpty ? t : (titleMap['en'] ?? '');
  }

  String localizedDescription(AppLanguage language) {
    final d = AppLanguage.getLocalizedText(descriptionMap, language);
    return d.isNotEmpty ? d : (descriptionMap['en'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'title': titleMap,
      'description': descriptionMap,
      'imageUrl': imageUrl,
      'rarity': rarity,
      'rarityPercentage': rarityPercentage,
      'isSecret': isSecret,
      'badgeIcon': badgeIcon,
    };
  }

  factory StoryEndingModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, String> parsedTitle = {};
    if (map['title'] is Map) {
      parsedTitle = (map['title'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['title'] is String) {
      parsedTitle = {'en': map['title'] as String};
    }

    Map<String, String> parsedDesc = {};
    if (map['description'] is Map) {
      parsedDesc = (map['description'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['description'] is String) {
      parsedDesc = {'en': map['description'] as String};
    }

    return StoryEndingModel(
      id: docId ?? map['id'] as String? ?? '',
      storyId: map['storyId'] as String? ?? '',
      titleMap: parsedTitle,
      descriptionMap: parsedDesc,
      imageUrl: map['imageUrl'] as String? ?? '',
      rarity: map['rarity'] as String? ?? 'Common',
      rarityPercentage: (map['rarityPercentage'] as num?)?.toDouble() ?? 25.0,
      isSecret: map['isSecret'] as bool? ?? (map['rarity'] == 'Secret'),
      badgeIcon: map['badgeIcon'] as String?,
    );
  }
}

import '../core/localization/app_language.dart';
import 'story_choice_model.dart';

class StoryNodeModel {
  final String nodeId;
  final String storyId;
  final Map<String, String> textMap;
  final String imageUrl;
  final bool isEnding;
  final String? endingId;
  final int sceneNumber;
  final Map<String, String>? speakerMap;
  final String? ambience;
  final List<StoryChoiceModel> choices;

  const StoryNodeModel({
    required this.nodeId,
    required this.storyId,
    required this.textMap,
    required this.imageUrl,
    this.isEnding = false,
    this.endingId,
    this.sceneNumber = 1,
    this.speakerMap,
    this.ambience,
    this.choices = const [],
  });

  String get text => localizedText(AppLanguage.en);
  String? get speaker => localizedSpeaker(AppLanguage.en);

  String localizedText(AppLanguage language) {
    final t = AppLanguage.getLocalizedText(textMap, language);
    return t.isNotEmpty ? t : (textMap['en'] ?? '');
  }

  String? localizedSpeaker(AppLanguage language) {
    if (speakerMap == null || speakerMap!.isEmpty) return null;
    final s = AppLanguage.getLocalizedText(speakerMap, language);
    return s.isNotEmpty ? s : speakerMap!['en'];
  }

  StoryNodeModel copyWith({
    String? nodeId,
    String? storyId,
    Map<String, String>? textMap,
    String? imageUrl,
    bool? isEnding,
    String? endingId,
    int? sceneNumber,
    Map<String, String>? speakerMap,
    String? ambience,
    List<StoryChoiceModel>? choices,
  }) {
    return StoryNodeModel(
      nodeId: nodeId ?? this.nodeId,
      storyId: storyId ?? this.storyId,
      textMap: textMap ?? this.textMap,
      imageUrl: imageUrl ?? this.imageUrl,
      isEnding: isEnding ?? this.isEnding,
      endingId: endingId ?? this.endingId,
      sceneNumber: sceneNumber ?? this.sceneNumber,
      speakerMap: speakerMap ?? this.speakerMap,
      ambience: ambience ?? this.ambience,
      choices: choices ?? this.choices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nodeId': nodeId,
      'storyId': storyId,
      'text': textMap,
      'imageUrl': imageUrl,
      'isEnding': isEnding,
      'endingId': endingId,
      'sceneNumber': sceneNumber,
      'speaker': speakerMap,
      'ambience': ambience,
      'choices': choices.map((c) => c.toMap()).toList(),
    };
  }

  factory StoryNodeModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawChoices = map['choices'];
    List<StoryChoiceModel> choicesList = [];
    if (rawChoices is List) {
      choicesList = rawChoices
          .map((c) => StoryChoiceModel.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();
    }

    Map<String, String> parsedText = {};
    if (map['text'] is Map) {
      parsedText = (map['text'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['text'] is String) {
      parsedText = {'en': map['text'] as String};
    }

    Map<String, String>? parsedSpeaker;
    if (map['speaker'] is Map) {
      parsedSpeaker = (map['speaker'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['speaker'] is String) {
      parsedSpeaker = {'en': map['speaker'] as String};
    }

    return StoryNodeModel(
      nodeId: docId ?? map['nodeId'] as String? ?? '',
      storyId: map['storyId'] as String? ?? '',
      textMap: parsedText,
      imageUrl: map['imageUrl'] as String? ?? '',
      isEnding: map['isEnding'] as bool? ?? false,
      endingId: map['endingId'] as String?,
      sceneNumber: (map['sceneNumber'] as num?)?.toInt() ?? 1,
      speakerMap: parsedSpeaker,
      ambience: map['ambience'] as String?,
      choices: choicesList,
    );
  }
}

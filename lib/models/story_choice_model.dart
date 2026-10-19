import '../core/localization/app_language.dart';

class StoryChoiceModel {
  final String id;
  final String nodeId;
  final Map<String, String> labelMap;
  final Map<String, String>? consequenceHintMap;
  final String? nextNodeId;
  final String? endingId;
  final String key; // e.g. "A", "B", "C"
  final String riskLevel; // 'safe', 'bold', 'danger', 'secret'

  const StoryChoiceModel({
    required this.id,
    required this.nodeId,
    required this.labelMap,
    this.consequenceHintMap,
    this.nextNodeId,
    this.endingId,
    this.key = 'A',
    this.riskLevel = 'bold',
  });

  bool get leadsToEnding => endingId != null && endingId!.isNotEmpty;

  String get label => localizedLabel(AppLanguage.en);
  String? get consequenceHint => localizedConsequenceHint(AppLanguage.en);

  String localizedLabel(AppLanguage language) {
    final text = AppLanguage.getLocalizedText(labelMap, language);
    return text.isNotEmpty ? text : (labelMap['en'] ?? '');
  }

  String? localizedConsequenceHint(AppLanguage language) {
    if (consequenceHintMap == null || consequenceHintMap!.isEmpty) return null;
    final text = AppLanguage.getLocalizedText(consequenceHintMap, language);
    return text.isNotEmpty ? text : consequenceHintMap!['en'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nodeId': nodeId,
      'label': labelMap,
      'consequenceHint': consequenceHintMap,
      'nextNodeId': nextNodeId,
      'endingId': endingId,
      'key': key,
      'riskLevel': riskLevel,
    };
  }

  factory StoryChoiceModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, String> parsedLabel = {};
    if (map['label'] is Map) {
      parsedLabel = (map['label'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['text'] is Map) {
      parsedLabel = (map['text'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['label'] is String) {
      parsedLabel = {'en': map['label'] as String};
    } else if (map['text'] is String) {
      parsedLabel = {'en': map['text'] as String};
    }

    Map<String, String>? parsedHint;
    if (map['consequenceHint'] is Map) {
      parsedHint = (map['consequenceHint'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else if (map['consequenceHint'] is String) {
      parsedHint = {'en': map['consequenceHint'] as String};
    }

    return StoryChoiceModel(
      id: docId ?? map['id'] as String? ?? '',
      nodeId: map['nodeId'] as String? ?? '',
      labelMap: parsedLabel,
      consequenceHintMap: parsedHint,
      nextNodeId: map['nextNodeId'] as String?,
      endingId: map['endingId'] as String?,
      key: map['key'] as String? ?? map['id']?.toString() ?? 'A',
      riskLevel: map['riskLevel'] as String? ?? 'bold',
    );
  }
}

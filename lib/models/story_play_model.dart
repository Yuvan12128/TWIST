class StoryPlayModel {
  final String id;
  final String storyId;
  final String userId;
  final List<String> nodesVisited;
  final List<String> choiceIds;
  final String? endingId;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  const StoryPlayModel({
    required this.id,
    required this.storyId,
    required this.userId,
    this.nodesVisited = const [],
    this.choiceIds = const [],
    this.endingId,
    this.isCompleted = false,
    required this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'userId': userId,
      'nodesVisited': nodesVisited,
      'choiceIds': choiceIds,
      'endingId': endingId,
      'isCompleted': isCompleted,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StoryPlayModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return StoryPlayModel(
      id: docId ?? map['id'] as String? ?? '',
      storyId: map['storyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      nodesVisited: (map['nodesVisited'] as List?)?.map((e) => e.toString()).toList() ?? [],
      choiceIds: (map['choiceIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      endingId: map['endingId'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
    );
  }
}

class ActivityModel {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'milestone', 'achievement', 'challenge'
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final String? storyId;
  final String? storyTitle;
  final String? targetEndingId;
  final String? actorId;
  final bool isRead;
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    this.actorId,
    this.storyId,
    this.storyTitle,
    this.targetEndingId,
    this.isRead = false,
    required this.createdAt,
  });

  ActivityModel copyWith({
    bool? isRead,
    String? actorId,
  }) {
    return ActivityModel(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      avatarUrl: avatarUrl,
      actorId: actorId ?? this.actorId,
      storyId: storyId,
      storyTitle: storyTitle,
      targetEndingId: targetEndingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'avatarUrl': avatarUrl,
      'actorId': actorId,
      'storyId': storyId,
      'storyTitle': storyTitle,
      'targetEndingId': targetEndingId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ActivityModel(
      id: docId ?? map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'like',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      actorId: map['actorId'] as String?,
      storyId: map['storyId'] as String?,
      storyTitle: map['storyTitle'] as String?,
      targetEndingId: map['targetEndingId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

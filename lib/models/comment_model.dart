class CommentModel {
  final String id;
  final String storyId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final int likes;
  final bool isLiked;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.likes = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  CommentModel copyWith({
    int? likes,
    bool? isLiked,
  }) {
    return CommentModel(
      id: id,
      storyId: storyId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      text: text,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CommentModel(
      id: docId ?? map['id'] as String? ?? '',
      storyId: map['storyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Explorer',
      userAvatar: map['userAvatar'] as String?,
      text: map['text'] as String? ?? '',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      isLiked: map['isLiked'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

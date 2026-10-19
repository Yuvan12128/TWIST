class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final int storiesPlayedCount;
  final int endingsFoundCount;
  final int choicesMadeCount;
  final int followersCount;
  final int followingCount;
  final bool isGuest;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio = 'Interactive story voyager 🎬 Finding all the secret endings.',
    this.storiesPlayedCount = 0,
    this.endingsFoundCount = 0,
    this.choicesMadeCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isGuest = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    int? storiesPlayedCount,
    int? endingsFoundCount,
    int? choicesMadeCount,
    int? followersCount,
    int? followingCount,
    bool? isGuest,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      storiesPlayedCount: storiesPlayedCount ?? this.storiesPlayedCount,
      endingsFoundCount: endingsFoundCount ?? this.endingsFoundCount,
      choicesMadeCount: choicesMadeCount ?? this.choicesMadeCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'storiesPlayedCount': storiesPlayedCount,
      'endingsFoundCount': endingsFoundCount,
      'choicesMadeCount': choicesMadeCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isGuest': isGuest,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      uid: docId ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Twist Explorer',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String? ?? 'Interactive story voyager 🎬 Finding all the secret endings.',
      storiesPlayedCount: (map['storiesPlayedCount'] as num?)?.toInt() ?? 0,
      endingsFoundCount: (map['endingsFoundCount'] as num?)?.toInt() ?? 0,
      choicesMadeCount: (map['choicesMadeCount'] as num?)?.toInt() ?? 0,
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      isGuest: map['isGuest'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

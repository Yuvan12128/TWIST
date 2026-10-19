class UserChoiceModel {
  final String id;
  final String userId;
  final String storyId;
  final String nodeId;
  final String choiceId;
  final String choiceLabel;
  final DateTime chosenAt;

  const UserChoiceModel({
    required this.id,
    required this.userId,
    required this.storyId,
    required this.nodeId,
    required this.choiceId,
    required this.choiceLabel,
    required this.chosenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'storyId': storyId,
      'nodeId': nodeId,
      'choiceId': choiceId,
      'choiceLabel': choiceLabel,
      'chosenAt': chosenAt.toIso8601String(),
    };
  }

  factory UserChoiceModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserChoiceModel(
      id: docId ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      storyId: map['storyId'] as String? ?? '',
      nodeId: map['nodeId'] as String? ?? '',
      choiceId: map['choiceId'] as String? ?? '',
      choiceLabel: map['choiceLabel'] as String? ?? '',
      chosenAt: map['chosenAt'] != null
          ? DateTime.tryParse(map['chosenAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

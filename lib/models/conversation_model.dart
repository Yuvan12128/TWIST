import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String lastMessage;
  final String lastMessageSenderId;
  final bool isLastMessageRead;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    this.participantNames = const {},
    this.participantAvatars = const {},
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.isLastMessageRead = false,
    required this.lastMessageAt,
    required this.createdAt,
  });

  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String otherParticipantName(String currentUserId) {
    final otherId = otherParticipantId(currentUserId);
    final name = participantNames[otherId];
    if (name != null && name.trim().isNotEmpty) return name;
    return 'Storyteller';
  }

  String? otherParticipantAvatar(String currentUserId) {
    final otherId = otherParticipantId(currentUserId);
    return participantAvatars[otherId];
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate().toLocal();
      if (val is DateTime) return val.toLocal();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed.toLocal();
      }
      return DateTime.now();
    }

    final rawNames = map['participantNames'];
    final namesMap = <String, String>{};
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k != null && v != null) namesMap[k.toString()] = v.toString();
      });
    }

    final rawAvatars = map['participantAvatars'];
    final avatarsMap = <String, String?>{};
    if (rawAvatars is Map) {
      rawAvatars.forEach((k, v) {
        if (k != null) avatarsMap[k.toString()] = v?.toString();
      });
    }

    return ConversationModel(
      id: docId,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: namesMap,
      participantAvatars: avatarsMap,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      isLastMessageRead: map['isLastMessageRead'] as bool? ?? false,
      lastMessageAt: parseDate(map['lastMessageAt']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'isLastMessageRead': isLastMessageRead,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    String? lastMessage,
    String? lastMessageSenderId,
    bool? isLastMessageRead,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      isLastMessageRead: isLastMessageRead ?? this.isLastMessageRead,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

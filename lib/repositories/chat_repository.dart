import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/firebase_service.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';

class ChatRepository {
  final _uuid = const Uuid();

  // In-memory cache for offline/testing support
  final Map<String, ConversationModel> _cachedConversations = {};
  final Map<String, List<ChatMessageModel>> _cachedMessages = {};

  final StreamController<List<ConversationModel>> _localConversationsController =
      StreamController<List<ConversationModel>>.broadcast();
  final Map<String, StreamController<List<ChatMessageModel>>> _localMessagesControllers = {};

  /// Computes a deterministic conversation ID for two users.
  /// The order of IDs does not matter: A and B will always get the same conversation ID.
  static String getConversationId(String uid1, String uid2) {
    if (uid1 == uid2) {
      throw ArgumentError('Self-chat is not allowed. UIDs must be distinct.');
    }
    final sorted = [uid1, uid2]..sort();
    return 'conv_${sorted[0]}_${sorted[1]}';
  }

  /// Opens an existing conversation or creates a new one deterministically
  Future<ConversationModel> getOrCreateConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    if (currentUser.uid == otherUser.uid) {
      throw ArgumentError('Cannot create conversation with yourself.');
    }

    final convId = getConversationId(currentUser.uid, otherUser.uid);

    // 1. Try Firestore if available
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final docRef = FirebaseService.firestore!.collection('conversations').doc(convId);
        final doc = await docRef.get();

        if (doc.exists && doc.data() != null) {
          final conv = ConversationModel.fromMap(doc.data()!, docId: doc.id);
          _cachedConversations[convId] = conv;
          return conv;
        }

        // Create new conversation document
        final now = DateTime.now();
        final sortedUids = [currentUser.uid, otherUser.uid]..sort();
        final newConv = ConversationModel(
          id: convId,
          participantIds: sortedUids,
          participantNames: {
            currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Storyteller',
            otherUser.uid: otherUser.displayName.isNotEmpty ? otherUser.displayName : 'Storyteller',
          },
          participantAvatars: {
            currentUser.uid: currentUser.photoUrl,
            otherUser.uid: otherUser.photoUrl,
          },
          lastMessage: '',
          lastMessageSenderId: '',
          lastMessageAt: now,
          createdAt: now,
        );

        await docRef.set(newConv.toMap(), SetOptions(merge: true));
        _cachedConversations[convId] = newConv;
        _emitLocalConversations(currentUser.uid);
        return newConv;
      } catch (e, stack) {
        debugPrint('ChatRepository getOrCreateConversation error: $e\n$stack');
        // Fallback to local cache if network error
      }
    }

    // 2. Local fallback
    if (_cachedConversations.containsKey(convId)) {
      return _cachedConversations[convId]!;
    }

    final now = DateTime.now();
    final sortedUids = [currentUser.uid, otherUser.uid]..sort();
    final localConv = ConversationModel(
      id: convId,
      participantIds: sortedUids,
      participantNames: {
        currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'Storyteller',
        otherUser.uid: otherUser.displayName.isNotEmpty ? otherUser.displayName : 'Storyteller',
      },
      participantAvatars: {
        if (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty)
          currentUser.uid: currentUser.photoUrl,
        if (otherUser.photoUrl != null && otherUser.photoUrl!.isNotEmpty)
          otherUser.uid: otherUser.photoUrl,
      },
      lastMessage: '',
      lastMessageSenderId: '',
      lastMessageAt: now,
      createdAt: now,
    );
    _cachedConversations[convId] = localConv;
    _emitLocalConversations(currentUser.uid);
    return localConv;
  }

  /// Real-time stream of all conversations where [currentUserId] is a participant
  Stream<List<ConversationModel>> streamConversations(String currentUserId) {
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        return FirebaseService.firestore!
            .collection('conversations')
            .where('participantIds', arrayContains: currentUserId)
            .snapshots()
            .map((snap) {
              final list = snap.docs
                  .map((d) => ConversationModel.fromMap(d.data(), docId: d.id))
                  .toList()
                ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
              for (final c in list) {
                _cachedConversations[c.id] = c;
              }
              return list;
            });
      } catch (e, stack) {
        debugPrint('ChatRepository streamConversations error: $e\n$stack');
        // Fallback to local stream
      }
    }

    // Local stream for testing or offline
    final initialList = _cachedConversations.values
        .where((c) => c.participantIds.contains(currentUserId))
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return Stream<List<ConversationModel>>.multi((controller) {
      controller.add(initialList);
      final sub = _localConversationsController.stream.listen((list) {
        final filtered = list.where((c) => c.participantIds.contains(currentUserId)).toList();
        controller.add(filtered);
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Real-time stream of messages in a conversation, paginated by [limit]
  Stream<List<ChatMessageModel>> streamMessages(String conversationId, {int limit = 30}) {
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        return FirebaseService.firestore!
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((snap) {
              return snap.docs
                  .map((d) => ChatMessageModel.fromMap(d.data(), docId: d.id))
                  .toList();
            });
      } catch (_) {
        // Fallback to local stream
      }
    }

    // Local stream for testing
    final list = _cachedMessages[conversationId] ?? [];
    final controller = _getOrCreateLocalMessageController(conversationId);

    return Stream<List<ChatMessageModel>>.multi((ctrl) {
      ctrl.add(list.take(limit).toList());
      final sub = controller.stream.listen((msgs) {
        ctrl.add(msgs.take(limit).toList());
      });
      ctrl.onCancel = () => sub.cancel();
    });
  }

  /// Sends a text message in [conversationId]
  Future<bool> sendMessage({
    required String conversationId,
    required UserModel sender,
    required UserModel recipient,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}';
    final now = DateTime.now();

    final message = ChatMessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: sender.uid,
      senderName: sender.displayName.isNotEmpty ? sender.displayName : 'Storyteller',
      text: cleanText,
      createdAt: now,
    );

    // 1. Commit to Firestore if available
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final firestore = FirebaseService.firestore!;
        final convRef = firestore.collection('conversations').doc(conversationId);
        final msgRef = convRef.collection('messages').doc(messageId);

        final batch = firestore.batch();

        batch.set(msgRef, {
          'id': messageId,
          'conversationId': conversationId,
          'senderId': sender.uid,
          'senderName': message.senderName,
          'text': cleanText,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final sortedUids = [sender.uid, recipient.uid]..sort();
        batch.set(convRef, {
          'id': conversationId,
          'participantIds': sortedUids,
          'lastMessage': cleanText,
          'lastMessageSenderId': sender.uid,
          'isLastMessageRead': false,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'participantNames': {
            sender.uid: message.senderName,
            recipient.uid: recipient.displayName.isNotEmpty ? recipient.displayName : 'Storyteller',
          },
          'participantAvatars': {
            if (sender.photoUrl != null && sender.photoUrl!.isNotEmpty)
              sender.uid: sender.photoUrl,
            if (recipient.photoUrl != null && recipient.photoUrl!.isNotEmpty)
              recipient.uid: recipient.photoUrl,
          },
        }, SetOptions(merge: true));

        await batch.commit();

        // Update local memory
        _recordLocalMessage(conversationId, message);
        _updateLocalConversation(conversationId, cleanText, sender.uid, now, isRead: false);
        return true;
      } catch (e, stack) {
        debugPrint('ChatRepository sendMessage error: $e\n$stack');
        // If error, fall through to local record for resilience
      }
    }

    // 2. Local fallback
    _recordLocalMessage(conversationId, message);
    _updateLocalConversation(conversationId, cleanText, sender.uid, now, isRead: false);
    return true;
  }

  /// Marks unread messages in [conversationId] sent by others as read by [currentUserId]
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    // 1. Update in Firestore if ready
    if (FirebaseService.isFirebaseReady && FirebaseService.firestore != null) {
      try {
        final firestore = FirebaseService.firestore!;
        final convRef = firestore.collection('conversations').doc(conversationId);
        final messagesRef = convRef.collection('messages');

        final unreadDocs = await messagesRef
            .where('isRead', isEqualTo: false)
            .get();

        final batch = firestore.batch();
        bool hasUpdates = false;

        for (final doc in unreadDocs.docs) {
          final data = doc.data();
          if (data['senderId'] != currentUserId) {
            batch.update(doc.reference, {
              'isRead': true,
              'readAt': FieldValue.serverTimestamp(),
            });
            hasUpdates = true;
          }
        }

        if (hasUpdates) {
          batch.update(convRef, {
            'isLastMessageRead': true,
          });
          await batch.commit();
        }
      } catch (e, stack) {
        debugPrint('ChatRepository markMessagesAsRead error: $e\n$stack');
      }
    }

    // 2. Update local memory
    final msgs = _cachedMessages[conversationId];
    if (msgs != null && msgs.isNotEmpty) {
      bool changed = false;
      final updated = msgs.map((m) {
        if (m.senderId != currentUserId && !m.isRead) {
          changed = true;
          return m.copyWith(isRead: true, readAt: DateTime.now());
        }
        return m;
      }).toList();

      if (changed) {
        _cachedMessages[conversationId] = updated;
        final ctrl = _getOrCreateLocalMessageController(conversationId);
        ctrl.add(List.unmodifiable(updated));
      }
    }

    final conv = _cachedConversations[conversationId];
    if (conv != null && conv.lastMessageSenderId != currentUserId && !conv.isLastMessageRead) {
      _cachedConversations[conversationId] = conv.copyWith(isLastMessageRead: true);
      _emitLocalConversations(currentUserId);
    }
  }

  void _recordLocalMessage(String conversationId, ChatMessageModel message) {
    final list = _cachedMessages.putIfAbsent(conversationId, () => []);
    list.insert(0, message);
    final controller = _getOrCreateLocalMessageController(conversationId);
    controller.add(List.unmodifiable(list));
  }

  void _updateLocalConversation(
    String conversationId,
    String lastMsg,
    String senderId,
    DateTime at, {
    bool isRead = false,
  }) {
    final existing = _cachedConversations[conversationId];
    if (existing != null) {
      final updated = existing.copyWith(
        lastMessage: lastMsg,
        lastMessageSenderId: senderId,
        isLastMessageRead: isRead,
        lastMessageAt: at,
      );
      _cachedConversations[conversationId] = updated;
      _emitLocalConversations(senderId);
    }
  }

  void _emitLocalConversations(String userId) {
    final list = _cachedConversations.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    _localConversationsController.add(list);
  }

  StreamController<List<ChatMessageModel>> _getOrCreateLocalMessageController(String conversationId) {
    return _localMessagesControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessageModel>>.broadcast(),
    );
  }
}

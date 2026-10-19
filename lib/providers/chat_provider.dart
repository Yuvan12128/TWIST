import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  List<ConversationModel> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;
  StreamSubscription<List<ConversationModel>>? _conversationsSub;

  // Active Chat State
  ConversationModel? _activeConversation;
  List<ChatMessageModel> _activeMessages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;
  int _currentLimit = 30;
  bool _hasMoreMessages = true;
  StreamSubscription<List<ChatMessageModel>>? _messagesSub;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;

  ConversationModel? get activeConversation => _activeConversation;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  bool get hasMoreMessages => _hasMoreMessages;
  int get currentLimit => _currentLimit;

  ChatProvider(this._chatRepository);

  /// Initializes the live conversations stream for [currentUserId]
  void initConversations(String currentUserId) {
    if (currentUserId.isEmpty) return;

    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    _conversationsSub?.cancel();
    _conversationsSub = _chatRepository.streamConversations(currentUserId).listen(
      (list) {
        _conversations = list;
        _isLoadingConversations = false;
        notifyListeners();
      },
      onError: (err) {
        _conversationsError = err.toString();
        _isLoadingConversations = false;
        notifyListeners();
      },
    );
  }

  /// Sets up or resumes a deterministic conversation with [otherUser]
  Future<ConversationModel?> openConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    if (currentUser.uid == otherUser.uid) {
      return null;
    }

    _isLoadingMessages = true;
    _currentLimit = 30;
    _hasMoreMessages = true;
    notifyListeners();

    try {
      final conv = await _chatRepository.getOrCreateConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );
      _activeConversation = conv;

      _subscribeToActiveMessages(conv.id, currentUser.uid);
      // Immediately mark unread messages as read
      _chatRepository.markMessagesAsRead(
        conversationId: conv.id,
        currentUserId: currentUser.uid,
      );
      return conv;
    } catch (e) {
      _isLoadingMessages = false;
      notifyListeners();
      return null;
    }
  }

  void _subscribeToActiveMessages(String conversationId, [String? currentUserId]) {
    _messagesSub?.cancel();
    _messagesSub = _chatRepository
        .streamMessages(conversationId, limit: _currentLimit)
        .listen(
      (messages) {
        _activeMessages = messages;
        _isLoadingMessages = false;
        // If received count is less than query limit, there are no more older messages
        if (messages.length < _currentLimit) {
          _hasMoreMessages = false;
        } else {
          _hasMoreMessages = true;
        }
        notifyListeners();

        // Mark unread messages from other participant as read
        if (currentUserId != null && currentUserId.isNotEmpty) {
          final hasUnread = messages.any((m) => m.senderId != currentUserId && !m.isRead);
          if (hasUnread) {
            _chatRepository.markMessagesAsRead(
              conversationId: conversationId,
              currentUserId: currentUserId,
            );
          }
        }
      },
      onError: (_) {
        _isLoadingMessages = false;
        notifyListeners();
      },
    );
  }

  /// Explicitly marks messages in the active conversation as read
  Future<void> markActiveMessagesAsRead(String currentUserId) async {
    if (_activeConversation == null || currentUserId.isEmpty) return;
    await _chatRepository.markMessagesAsRead(
      conversationId: _activeConversation!.id,
      currentUserId: currentUserId,
    );
  }

  /// Paginates older messages by fetching the next batch
  void loadMoreMessages([String? currentUserId]) {
    if (!_hasMoreMessages || _isLoadingMessages || _activeConversation == null) return;

    _currentLimit += 30;
    _subscribeToActiveMessages(_activeConversation!.id, currentUserId);
  }

  /// Sends a text message to [recipient] in the active conversation
  Future<bool> sendMessage({
    required String text,
    required UserModel sender,
    required UserModel recipient,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || _activeConversation == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      final success = await _chatRepository.sendMessage(
        conversationId: _activeConversation!.id,
        sender: sender,
        recipient: recipient,
        text: clean,
      );
      return success;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Clears active conversation state when exiting ChatScreen
  void closeActiveConversation() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _activeConversation = null;
    _activeMessages = [];
    _isLoadingMessages = false;
    _isSending = false;
    _currentLimit = 30;
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/conversation_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/cached_image.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatProv = context.read<ChatProvider>();
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser != null &&
          (chatProv.activeConversation == null ||
              chatProv.activeConversation!.id != widget.conversation.id)) {
        chatProv.openConversation(
          currentUser: currentUser,
          otherUser: widget.otherUser,
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 80) {
      context.read<ChatProvider>().loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    _textController.clear();
    setState(() => _isComposing = false);

    await context.read<ChatProvider>().sendMessage(
          text: text,
          sender: currentUser,
          recipient: widget.otherUser,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final chatProv = context.watch<ChatProvider>();
    final messages = chatProv.activeMessages;
    final otherName = widget.otherUser.displayName.isNotEmpty
        ? widget.otherUser.displayName
        : widget.conversation.otherParticipantName(currentUser?.uid ?? '');
    final otherEmail = widget.otherUser.email;
    final otherHandle = otherEmail.contains('@')
        ? otherEmail.split('@').first
        : otherName.toLowerCase().replaceAll(' ', '');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ChatProvider>().closeActiveConversation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              context.read<ChatProvider>().closeActiveConversation();
              Navigator.of(context).pop();
            },
          ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: widget.otherUser.photoUrl != null
                    ? CachedImage(
                        imageUrl: widget.otherUser.photoUrl!,
                        width: 38,
                        height: 38,
                      )
                    : const Icon(Icons.person, color: AppColors.textMuted, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: AppTypography.storyCardTitle.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@$otherHandle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages Area
            Expanded(
              child: chatProv.isLoadingMessages && messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                      ),
                    )
                  : messages.isEmpty
                      ? _buildEmptyChat(otherName)
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == currentUser?.uid;

                            // Date separator logic for reversed list
                            final isFirstInDay = index == messages.length - 1 ||
                                !_isSameDay(msg.createdAt, messages[index + 1].createdAt);

                            final bubble = _buildMessageBubble(msg, isMe);
                            if (isFirstInDay) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDateSeparator(msg.createdAt),
                                  bubble,
                                ],
                              );
                            }
                            return bubble;
                          },
                        ),
            ),

            // Message Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    ),
  );
}

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  Widget _buildDateSeparator(DateTime dateTime) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Text(
          Formatters.chatDateSeparator(dateTime),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat(String otherName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryYellow, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Private 1-to-1 Chat',
              style: AppTypography.screenTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Start your conversation with $otherName. Messages are private and securely delivered in real time.',
              textAlign: TextAlign.center,
              style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryYellow : AppColors.cardBackground,
              border: isMe ? null : Border.all(color: AppColors.border),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: isMe ? const Color(0xFF0B0B0F) : Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.chatMessageTime(msg.createdAt),
                      style: TextStyle(
                        color: isMe ? const Color(0x990B0B0F) : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: msg.isRead
                            ? const Color(0xFF007AFF) // Electric Blue Tick when read!
                            : const Color(0x770B0B0F), // Grey unread tick
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) {
                  final composing = val.trim().isNotEmpty;
                  if (composing != _isComposing) {
                    setState(() => _isComposing = composing);
                  }
                },
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13.5),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isComposing ? _handleSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isComposing ? AppColors.primaryYellow : AppColors.surfaceLight,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _isComposing ? const Color(0xFF0B0B0F) : AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

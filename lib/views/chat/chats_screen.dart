import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/user_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/glass_card.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ChatProvider>().initConversations(user.uid);
      }
    });
  }

  void _openChat(ConversationModel conv) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    final otherUid = conv.otherParticipantId(currentUser.uid);
    final otherName = conv.otherParticipantName(currentUser.uid);
    final otherAvatar = conv.otherParticipantAvatar(currentUser.uid);

    final otherUser = UserModel(
      uid: otherUid,
      email: '',
      displayName: otherName,
      photoUrl: otherAvatar,
      createdAt: DateTime.now(),
    );

    await context.read<ChatProvider>().openConversation(
          currentUser: currentUser,
          otherUser: otherUser,
        );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conv,
          otherUser: otherUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final chatProv = context.watch<ChatProvider>();
    final conversations = chatProv.conversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Chats',
          style: AppTypography.screenTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: chatProv.isLoadingConversations && conversations.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                ),
              )
            : conversations.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final otherName = conv.otherParticipantName(currentUser?.uid ?? '');
                      final otherAvatar = conv.otherParticipantAvatar(currentUser?.uid ?? '');
                      final isLastFromMe = conv.lastMessageSenderId == currentUser?.uid;

                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        onTap: () => _openChat(conv),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceLight,
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: otherAvatar != null
                                    ? CachedImage(
                                        imageUrl: otherAvatar,
                                        width: 48,
                                        height: 48,
                                      )
                                    : const Icon(Icons.person, color: AppColors.textMuted, size: 26),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Name & Preview
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          otherName,
                                          style: AppTypography.storyCardTitle.copyWith(fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        Formatters.chatListTime(conv.lastMessageAt),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (isLastFromMe && conv.lastMessage.isNotEmpty) ...[
                                        Icon(
                                          Icons.done_all_rounded,
                                          size: 14,
                                          color: conv.isLastMessageRead
                                              ? const Color(0xFF007AFF)
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          conv.lastMessage.isNotEmpty
                                              ? conv.lastMessage
                                              : 'Conversation started',
                                          style: AppTypography.caption.copyWith(
                                            color: conv.lastMessage.isNotEmpty
                                                ? AppColors.secondaryText
                                                : AppColors.textPlaceholder,
                                            fontSize: 12.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.textMuted,
                              size: 13,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 44,
                color: AppColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Conversations Yet',
              style: AppTypography.screenTitle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for storytellers in Explore, view their profile, and tap "Message" to begin a private conversation.',
              textAlign: TextAlign.center,
              style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

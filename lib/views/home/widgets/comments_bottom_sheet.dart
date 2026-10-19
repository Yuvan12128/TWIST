import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/comment_model.dart';
import '../../../models/story_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/story_repository.dart';
import '../../../widgets/cached_image.dart';

class CommentsBottomSheet extends StatefulWidget {
  final StoryModel story;

  const CommentsBottomSheet({super.key, required this.story});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final storyRepo = context.read<StoryRepository>();
    final list = await storyRepo.getComments(widget.story.id);
    if (mounted) {
      setState(() {
        _comments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isPosting = true);
    _commentController.clear();

    final storyRepo = context.read<StoryRepository>();
    final newComment = await storyRepo.addComment(widget.story.id, text, user);

    if (mounted) {
      setState(() {
        _comments.insert(0, newComment);
        _isPosting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textPlaceholder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${_comments.length})',
                  style: AppTypography.screenTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textPlaceholder),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet.',
                              style: AppTypography.storyCardDescription.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to share your thoughts on this story!',
                              style: AppTypography.caption.copyWith(color: AppColors.textPlaceholder),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: comment.userAvatar != null
                                    ? CachedImage(
                                        imageUrl: comment.userAvatar!,
                                        width: 36,
                                        height: 36,
                                      )
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        color: AppColors.surfaceLight,
                                        child: const Icon(Icons.person, color: AppColors.textMuted, size: 20),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: AppTypography.storyCardTitle.copyWith(fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Formatters.timeAgo(comment.createdAt),
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: AppTypography.storyCardDescription.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: comment.isLiked ? AppColors.primaryPink : AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _comments[index] = comment.copyWith(
                                      isLiked: !comment.isLiked,
                                      likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
                                    );
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Bottom Input Field
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a reaction or choice advice...',
                        hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isPosting ? null : _postComment,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryYellow),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.primaryYellow, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

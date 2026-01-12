import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.green500,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  style: TextStyle(color: AppColors.white900),
                  decoration: InputDecoration(
                    hintText: 'Search for a chat...',
                    hintStyle: TextStyle(
                      color: AppColors.white900.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.white900),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // Conversations list
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Text(
                        'No conversations yet',
                        style: ShadTheme.of(
                          context,
                        ).textTheme.h4.copyWith(color: AppColors.gray400),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.gray100,
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: CachedNetworkImageProvider(
                            conv.displayAvatar.isNotEmpty
                                ? conv.displayAvatar
                                : 'https://github.com/shadcn.png',
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTimestamp(conv.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                        subtitle: conv.lastMessageContent != null
                            ? Text(
                                conv.lastMessageContent!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          context.push('/chat/${conv.id}');
                        },
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'Error loading conversations',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

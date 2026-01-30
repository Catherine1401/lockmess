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
    // Only show direct conversations
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

            // Conversations list (direct only)
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  // Filter only direct conversations
                  final directConvs = conversations
                      .where((c) => c.isDirect)
                      .toList();

                  if (directConvs.isEmpty) {
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
                    itemCount: directConvs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.gray100,
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      final conv = directConvs[index];
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
                        title: Text(
                          conv.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          conv.lastMessageContent ?? 'No messages yet',
                          style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimestamp(conv.lastMessageTime),
                              style: TextStyle(
                                color: AppColors.gray400,
                                fontSize: 12,
                              ),
                            ),
                            if (conv.unreadCount > 0) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.green500,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  conv.unreadCount > 99
                                      ? '99+'
                                      : '${conv.unreadCount}',
                                  style: TextStyle(
                                    color: AppColors.white900,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () => context.push('/chat/${conv.id}'),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error loading conversations')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

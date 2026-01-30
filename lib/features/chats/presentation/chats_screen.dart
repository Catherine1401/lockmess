import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
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
                  controller: _searchController,
                  style: TextStyle(color: AppColors.white900),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a chat...',
                    hintStyle: TextStyle(
                      color: AppColors.white900.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.white900),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.white900),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
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
                  var directConvs = conversations
                      .where((c) => c.isDirect)
                      .toList();

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    directConvs = directConvs.where((c) {
                      final nameMatch = c.displayName.toLowerCase().contains(
                        _searchQuery,
                      );
                      final messageMatch =
                          c.lastMessageContent?.toLowerCase().contains(
                            _searchQuery,
                          ) ??
                          false;
                      return nameMatch || messageMatch;
                    }).toList();
                  }

                  if (directConvs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_searchQuery.isNotEmpty) ...[
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.gray300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chats found for "$_searchQuery"',
                              style: TextStyle(
                                color: AppColors.gray400,
                                fontSize: 16,
                              ),
                            ),
                          ] else
                            Text(
                              'No conversations yet',
                              style: ShadTheme.of(
                                context,
                              ).textTheme.h4.copyWith(color: AppColors.gray400),
                            ),
                        ],
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
                        title: _buildHighlightedText(
                          conv.displayName,
                          _searchQuery,
                          TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.black900,
                          ),
                        ),
                        subtitle: _buildHighlightedText(
                          conv.lastMessageContent ?? 'No messages yet',
                          _searchQuery,
                          TextStyle(color: AppColors.gray400, fontSize: 14),
                          maxLines: 1,
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

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle, {
    int maxLines = 1,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final textLower = text.toLowerCase();
    final index = textLower.indexOf(query);

    if (index == -1) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index), style: baseStyle),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.green500,
              backgroundColor: AppColors.green100,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
              style: baseStyle,
            ),
        ],
      ),
    );
  }
}

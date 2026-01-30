import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                    hintText: 'Search groups...',
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

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.green500,
              unselectedLabelColor: AppColors.gray400,
              indicatorColor: AppColors.green500,
              tabs: [
                Tab(text: 'Groups'),
                Tab(text: 'Channels'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationsList(
                    ref.watch(groupConversationsProvider),
                  ),
                  _buildChannelsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green500,
        onPressed: () => _showCreateMenu(context),
        child: Icon(Icons.add, color: AppColors.white900),
      ),
    );
  }

  Widget _buildConversationsList(AsyncValue conversationsAsync) {
    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Text(
              'No groups yet',
              style: ShadTheme.of(
                context,
              ).textTheme.h4.copyWith(color: AppColors.gray400),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: conversations.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.gray100, indent: 76),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show member count badge
                  if (conv.memberCount != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            conv.isGroup ? Icons.group : Icons.tag,
                            size: 12,
                            color: AppColors.gray400,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${conv.memberCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                conv.lastMessageContent ?? 'No messages yet',
                style: TextStyle(color: AppColors.gray400, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(conv.lastMessageTime),
                    style: TextStyle(color: AppColors.gray400, fontSize: 12),
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
                        conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
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
      error: (error, _) => Center(child: Text('Error loading groups')),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.group, color: AppColors.green500),
              title: Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-group');
              },
            ),
            ListTile(
              leading: Icon(Icons.tag, color: AppColors.green500),
              title: Text('New Channel'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-channel');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelsTab() {
    final myChannelsAsync = ref.watch(channelConversationsProvider);
    final recommendedAsync = ref.watch(recommendedChannelsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Channels Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'My Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black900,
              ),
            ),
          ),
          myChannelsAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'You haven\'t joined any channels yet',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: channels.length,
                itemBuilder: (context, index) =>
                    _buildChannelTile(channels[index], isJoined: true),
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (_, __) => Text('Error loading channels'),
          ),

          SizedBox(height: 24),

          // Discover Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Discover Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black900,
              ),
            ),
          ),
          recommendedAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No recommended channels based on your hobbies',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: channels.length,
                itemBuilder: (context, index) =>
                    _buildChannelTile(channels[index], isJoined: false),
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (_, __) => Text('Error loading recommendations'),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChannelTile(dynamic conv, {required bool isJoined}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conv.lastMessageContent ?? 'No messages yet',
        style: TextStyle(color: AppColors.gray400, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isJoined
          ? Text(
              _formatTimestamp(conv.lastMessageTime),
              style: TextStyle(color: AppColors.gray400, fontSize: 12),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green500,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Join',
                style: TextStyle(
                  color: AppColors.white900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      onTap: () {
        if (isJoined) {
          context.push('/chat/${conv.id}');
        } else {
          context.push('/channel/${conv.id}');
        }
      },
    );
  }
}

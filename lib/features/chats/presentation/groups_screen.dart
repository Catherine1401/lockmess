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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedHobbyId; // null means "All"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: Column(
          children: [
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
                    hintText: 'Search groups...',
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

            // Hobby Filter Chips
            _buildHobbyChips(),

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
                    _searchQuery,
                  ),
                  _buildChannelsTab(_searchQuery),
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

  Widget _buildConversationsList(
    AsyncValue conversationsAsync,
    String searchQuery,
  ) {
    return conversationsAsync.when(
      data: (conversations) {
        // Apply search filter
        var filteredConvs = List.from(conversations);
        if (searchQuery.isNotEmpty) {
          filteredConvs = filteredConvs.where((c) {
            final nameMatch = c.displayName.toLowerCase().contains(searchQuery);
            final messageMatch =
                c.lastMessageContent?.toLowerCase().contains(searchQuery) ??
                false;
            return nameMatch || messageMatch;
          }).toList();
        }

        if (filteredConvs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (searchQuery.isNotEmpty) ...[
                  Icon(Icons.search_off, size: 48, color: AppColors.gray300),
                  const SizedBox(height: 16),
                  Text(
                    'No groups found for "$searchQuery"',
                    style: TextStyle(color: AppColors.gray400, fontSize: 16),
                  ),
                ] else
                  Text(
                    'No groups yet',
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
          itemCount: filteredConvs.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.gray100, indent: 76),
          itemBuilder: (context, index) {
            final conv = filteredConvs[index];
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
                    child: _buildHighlightedText(
                      conv.displayName,
                      searchQuery,
                      TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.black900,
                      ),
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
              subtitle: _buildHighlightedText(
                conv.lastMessageContent ?? 'No messages yet',
                searchQuery,
                TextStyle(color: AppColors.gray400, fontSize: 14),
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

  Widget _buildHobbyChips() {
    final hobbiesAsync = ref.watch(hobbiesListProvider);

    return hobbiesAsync.when(
      data: (hobbies) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: hobbies.length + 1, // +1 for "All" chip
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" chip
                final isSelected = _selectedHobbyId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('All'),
                    selected: isSelected,
                    selectedColor: AppColors.green500.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.green500,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.green500
                          : AppColors.gray400,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedHobbyId = null;
                      });
                    },
                  ),
                );
              }

              final hobby = hobbies[index - 1];
              final hobbyId = hobby['id'].toString();
              final hobbyName = hobby['name'] as String;
              final isSelected = _selectedHobbyId == hobbyId;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(hobbyName),
                  selected: isSelected,
                  selectedColor: AppColors.green500.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.green500,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.green500 : AppColors.gray400,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedHobbyId = isSelected ? null : hobbyId;
                    });
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(height: 50),
      error: (_, __) => SizedBox(height: 50),
    );
  }

  Widget _buildChannelsTab(String searchQuery) {
    // Use paginated provider for channels
    final mapState = ref.watch(paginatedConversationsMapProvider);
    final paginatedChannelsState =
        mapState['channel'] ??
        const PaginatedConversationsState(isLoading: true);

    // Ensure initialized
    if (mapState['channel'] == null) {
      Future.microtask(
        () => ref
            .read(paginatedConversationsMapProvider.notifier)
            .init('channel'),
      );
    }

    final conversations = paginatedChannelsState.conversations;
    final recommendedAsync = ref.watch(recommendedChannelsProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          ref
              .read(paginatedConversationsMapProvider.notifier)
              .loadMore('channel');
        }
        return false;
      },
      child: CustomScrollView(
        key: PageStorageKey('channels_tab'),
        slivers: [
          // My Channels Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'My Channels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black900,
                ),
              ),
            ),
          ),

          // My Channels List
          if (paginatedChannelsState.isLoading && conversations.isEmpty)
            SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (conversations.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'You haven\'t joined any channels yet',
                  style: TextStyle(color: AppColors.gray400),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Loading indicator at bottom of list
                  if (index == conversations.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  // Filter locally if searching (though ideally backend should handle this for paginated)
                  // For now, simpler to just show what we have
                  final channel = conversations[index];
                  if (searchQuery.isNotEmpty &&
                      !channel.displayName.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      )) {
                    return SizedBox.shrink(); // Hide unmatched, imperfect but simple
                  }

                  return _buildChannelTile(
                    channel,
                    isJoined: true,
                    searchQuery: searchQuery,
                  );
                },
                childCount:
                    conversations.length +
                    (paginatedChannelsState.isLoading ? 1 : 0),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Discover Channels Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Discover Channels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black900,
                ),
              ),
            ),
          ),

          // Discover List
          recommendedAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No recommended channels based on your hobbies',
                      style: TextStyle(color: AppColors.gray400),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildChannelTile(
                    channels[index],
                    isJoined: false,
                    searchQuery: searchQuery,
                  ),
                  childCount: channels.length,
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Center(child: Text('Error loading recommendations')),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildChannelTile(
    dynamic conv, {
    required bool isJoined,
    String searchQuery = '',
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        searchQuery,
        TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conv.lastMessageContent ?? 'No messages yet',
            style: TextStyle(color: AppColors.gray400, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isJoined) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  '${conv.memberCount ?? 0} members',
                  style: TextStyle(color: AppColors.gray400, fontSize: 12),
                ),
                if (conv.recentMemberAvatars != null &&
                    (conv.recentMemberAvatars as List).isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 18,
                    width: 60,
                    child: Stack(
                      children: [
                        for (
                          var i = 0;
                          i < (conv.recentMemberAvatars as List).take(3).length;
                          i++
                        )
                          Positioned(
                            left: i * 14.0,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: AppColors.white900,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundImage: CachedNetworkImageProvider(
                                  conv.recentMemberAvatars[i],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
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

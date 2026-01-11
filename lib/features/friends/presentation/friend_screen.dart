import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/features/friends/domain/entities/friend_request.dart';
import 'package:lockmess/features/friends/presentation/viewmodel/friend_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FriendScreen extends ConsumerWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            MultiSliver(
              children: [
                const SizedBox(height: 24),

                // Close button
                _buildCloseButton(context),
                const SizedBox(height: 20),

                // Friend count title
                _buildFriendCount(context, friendsAsync),
                const SizedBox(height: 16),

                // Search button
                _buildSearchButton(context),
                const SizedBox(height: 16),

                // "Find friends from other apps" label
                _buildSocialLabel(context),
                const SizedBox(height: 12),

                // Social media icons
                _buildSocialIcons(context),
                const SizedBox(height: 24),

                // Friend requests section (if any)
                requestsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) return SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(
                          context,
                          'Friend Requests',
                          Icons.person_add,
                        ),
                        const SizedBox(height: 12),
                        ...requests.map(
                          (req) => _buildRequestItem(context, ref, req),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                  loading: () => SizedBox(),
                  error: (_, __) => SizedBox(),
                ),

                // "Your friends" label
                _buildSectionLabel(context, 'Your friends', Icons.people),
                const SizedBox(height: 12),
              ],
            ),

            // Friends list
            friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          'No friends yet',
                          style: ShadTheme.of(context).textTheme.h4,
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= 3 && friends.length > 3) {
                      // Show only first 3, then "See more" button
                      return index == 3
                          ? _buildSeeMoreButton(context)
                          : SizedBox.shrink();
                    }
                    if (index >= friends.length) return SizedBox.shrink();
                    final friend = friends[index];
                    return _buildFriendItem(context, friend);
                  }, childCount: friends.length > 3 ? 4 : friends.length),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: Center(child: Text("Error loading friends")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white900,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                      color: AppColors.gray500.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                child: Icon(Icons.close, size: 20, color: AppColors.black900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCount(
    BuildContext context,
    AsyncValue<List<Profile>> friendsAsync,
  ) {
    return friendsAsync.when(
      data: (friends) => Text(
        '${friends.length} Friends',
        textAlign: TextAlign.center,
        style: ShadTheme.of(context).textTheme.custom['quantityFrinds'],
      ),
      loading: () => Text(
        'Loading...',
        textAlign: TextAlign.center,
        style: ShadTheme.of(context).textTheme.custom['quantityFrinds'],
      ),
      error: (_, __) => Text(
        '0 Friends',
        textAlign: TextAlign.center,
        style: ShadTheme.of(context).textTheme.custom['quantityFrinds'],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/search-friend'),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.green500,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Make a new friend',
                    textAlign: TextAlign.center,
                    style: ShadTheme.of(context).textTheme.custom['inSearch']!
                        .copyWith(color: AppColors.white900),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.search, color: AppColors.white900, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 18, color: AppColors.gray200),
          const SizedBox(width: 8),
          Text(
            'Find friends from other apps',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray200,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSocialIcon('Messenger', Icons.messenger, [
            Color(0xFF0084FF),
            Color(0xFF00C6FF),
          ]),
          _buildSocialIcon('Insta', Icons.photo_camera, [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
          ]),
          _buildSocialIcon('Imessage', Icons.message, [
            Color(0xFF34C759),
            Color(0xFF30D158),
          ]),
          _buildSocialIcon('Other', Icons.link, [
            Colors.black87,
            Colors.black87,
          ]),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
    String label,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.black900,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray200),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray200,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    WidgetRef ref,
    FriendRequest req,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green500, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                req.senderAvatar.isNotEmpty
                    ? req.senderAvatar
                    : 'https://github.com/shadcn.png',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.senderName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black900,
                  ),
                ),
                Text(
                  'Sent a friend request',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.check_circle, color: AppColors.green500),
            onPressed: () {
              ref.read(friendControllerProvider).acceptRequest(req.senderId);
            },
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              ref.read(friendControllerProvider).declineRequest(req.senderId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(BuildContext context, Profile friend) {
    // Get random color border for avatar
    final colors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFFF69B4), // Pink
      Color(0xFF87CEEB), // Sky blue
    ];
    final borderColor = colors[friend.id.hashCode % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/user-profile', extra: friend),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 3),
              ),
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  friend.avatarUrl.isNotEmpty
                      ? friend.avatarUrl
                      : 'https://github.com/shadcn.png',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                friend.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'See more',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black900,
            ),
          ),
        ),
      ),
    );
  }
}

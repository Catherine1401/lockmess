import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/presentation/view/conversation_search_screen.dart';

class GroupChatInfoDrawer extends ConsumerWidget {
  final Conversation conversation;

  const GroupChatInfoDrawer({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupName = conversation.name ?? 'Group';
    final avatarUrl = conversation.avatarUrl?.isNotEmpty == true
        ? conversation.avatarUrl!
        : 'https://github.com/shadcn.png';

    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: Column(
          children: [
            // Header with 3-dot menu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.more_vert, color: AppColors.black900),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Avatar with green border and edit icon
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green500, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  ),
                ),
                // Edit icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white900,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200, width: 1),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Group name
            Text(
              groupName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black900,
              ),
            ),

            const SizedBox(height: 8),

            // Share link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 16, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text(
                  'Share',
                  style: TextStyle(fontSize: 14, color: AppColors.gray400),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Menu items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_add_outlined,
                      label: 'Add member',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      iconWidget: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray400,
                        ),
                      ),
                      label: 'Nick names',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.people_outline,
                      label: 'See chat members',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.search,
                      label: 'Search',
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        showConversationSearch(
                          context,
                          conversation.id,
                          conversation.name ?? 'Group',
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notification',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.folder_outlined,
                      label: 'File',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.logout,
                      label: 'Leave chat',
                      onTap: () {},
                      isDestructive: true,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppColors.gray400;
    final textColor = isDestructive ? Colors.red : AppColors.black900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (iconWidget != null)
              SizedBox(width: 24, child: Center(child: iconWidget))
            else
              Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

/// Shows the group chat info drawer from the right side (7/8 screen width)
void showGroupChatInfoDrawer(BuildContext context, Conversation conversation) {
  final screenWidth = MediaQuery.of(context).size.width;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'GroupChatInfo',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: screenWidth * 7 / 8,
            decoration: BoxDecoration(
              color: AppColors.white900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: GroupChatInfoDrawer(conversation: conversation),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}

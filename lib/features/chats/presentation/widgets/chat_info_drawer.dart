import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/presentation/view/conversation_search_screen.dart';

class ChatInfoDrawer extends ConsumerWidget {
  final Conversation conversation;

  const ChatInfoDrawer({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUser = conversation.otherUser;
    final displayName = conversation.displayName;
    final username = otherUser?.username ?? 'unknown';
    final avatarUrl = conversation.displayAvatar.isNotEmpty
        ? conversation.displayAvatar
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

            // Avatar with green border
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

            const SizedBox(height: 16),

            // Name
            Text(
              displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black900,
              ),
            ),

            const SizedBox(height: 4),

            // ID with copy button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ID: @$username',
                  style: TextStyle(fontSize: 14, color: AppColors.gray400),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: username));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ID copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: AppColors.gray400,
                  ),
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
                      icon: Icons.person_outline,
                      label: 'Profile',
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
                      label: 'Nick name',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.group_add_outlined,
                      label: 'Create group chat',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildMenuItem(
                      icon: Icons.search,
                      label: 'Search in conversation',
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        showConversationSearch(
                          context,
                          conversation.id,
                          conversation.displayName,
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
                      icon: Icons.block,
                      label: 'Block',
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

/// Shows the chat info drawer from the right side (7/8 screen width)
void showChatInfoDrawer(BuildContext context, Conversation conversation) {
  final screenWidth = MediaQuery.of(context).size.width;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'ChatInfo',
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
            child: ChatInfoDrawer(conversation: conversation),
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

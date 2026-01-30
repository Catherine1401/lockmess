import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';

class ChannelProfileScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelProfileScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChannelProfileScreen> createState() =>
      _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends ConsumerState<ChannelProfileScreen> {
  bool _isJoining = false;

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChannel() async {
    setState(() => _isJoining = true);

    try {
      await ref.read(groupControllerProvider).joinChannel(widget.channelId);

      if (mounted) {
        // Navigate to the chat
        context.pushReplacement('/chat/${widget.channelId}');
      }
    } catch (e) {
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('already exists')) {
        // If already joined (race condition or state mismatch), just go to chat
        if (mounted) context.pushReplacement('/chat/${widget.channelId}');
      } else {
        _showError('Failed to join channel: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _leaveChannel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Channel'),
        content: Text('Are you sure you want to leave this channel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isJoining = true);

    try {
      await ref
          .read(groupControllerProvider)
          .leaveConversation(widget.channelId);

      if (mounted) {
        context.pop(); // Return to previous screen
      }
    } catch (e) {
      _showError('Failed to leave channel: $e');
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(conversationProvider(widget.channelId));
    final hobbiesAsync = ref.watch(channelHobbiesProvider(widget.channelId));
    final currentUser = ref.watch(supabase).client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: AppBar(
        backgroundColor: AppColors.white900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black900),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Channel',
          style: TextStyle(
            color: AppColors.black900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: channelAsync.when(
        data: (channel) {
          if (channel == null) {
            return Center(child: Text('Channel not found'));
          }

          final isJoined =
              currentUser != null &&
              (channel.memberIds?.contains(currentUser.id) ?? false);

          // Format member count with dots (e.g., 2.014)
          String formattedMembers = channel.memberCount.toString();
          if (channel.memberCount != null && channel.memberCount! > 1000) {
            final count = channel.memberCount!;
            formattedMembers =
                '${(count / 1000).floor()}.${(count % 1000).toString().padLeft(3, '0')}';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Green Background Area + Avatar
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 120, // Adjust height as needed
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.green100, // Light green background
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50, // Half of avatar height
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white900,
                          border: Border.all(
                            color: AppColors.green500,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: CachedNetworkImageProvider(
                            channel.displayAvatar.isNotEmpty
                                ? channel.displayAvatar
                                : 'https://github.com/shadcn.png',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 60), // Space for Avatar
                // Channel Name
                Text(
                  channel.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black900,
                  ),
                ),

                SizedBox(height: 4),

                // Share Button (Mock functionality)
                GestureDetector(
                  onTap: () {
                    // Replaced SnackBar with Dialog for safety or just print
                    _showError('Sharing is coming soon!');
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: AppColors.gray400,
                        size: 24,
                      ),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: AppColors.gray400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Join/Chat Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isJoining
                          ? null
                          : (isJoined
                                ? () => context.push('/chat/${channel.id}')
                                : _joinChannel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined
                            ? AppColors.white900
                            : AppColors.green500,
                        foregroundColor: isJoined
                            ? AppColors.green500
                            : AppColors.black900,
                        side: isJoined
                            ? BorderSide(color: AppColors.green500)
                            : null,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isJoining
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.black900,
                              ),
                            )
                          : Text(
                              isJoined ? 'Go to Chat' : 'Join the channel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),

                if (isJoined) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isJoining ? null : _leaveChannel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Leave Channel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 32),

                // Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic (Hobbies)
                      Text(
                        'Topic',
                        style: TextStyle(
                          color: AppColors.gray300,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      hobbiesAsync.when(
                        data: (hobbies) {
                          final topic = hobbies.isNotEmpty
                              ? hobbies.first
                              : 'General';
                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white900,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black900,
                              ),
                            ),
                          );
                        },
                        loading: () => SizedBox.shrink(),
                        error: (_, __) => Text('Error loading topic'),
                      ),

                      SizedBox(height: 20),

                      // Number of members
                      Text(
                        'Number of members',
                        style: TextStyle(
                          color: AppColors.gray300,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white900,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$formattedMembers members',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black900,
                              ),
                            ),
                            Spacer(),
                            // Member Avatars Stack
                            SizedBox(
                              width: 80, // Approximate width for 3 avatars
                              height: 32,
                              child: Stack(
                                children: [
                                  if (channel.recentMemberAvatars != null)
                                    for (
                                      int i = 0;
                                      i < channel.recentMemberAvatars!.length;
                                      i++
                                    )
                                      Positioned(
                                        right: i * 20.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.white900,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                                  channel
                                                      .recentMemberAvatars![i],
                                                ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Channel Information (Description)
                      Text(
                        'Channel information',
                        style: TextStyle(
                          color: AppColors.gray300,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white900,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          channel.description ??
                              'No description available for this channel.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.black900.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading channel')),
      ),
    );
  }
}

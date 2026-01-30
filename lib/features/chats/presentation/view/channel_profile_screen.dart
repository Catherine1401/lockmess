import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
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

  Future<void> _joinChannel() async {
    setState(() => _isJoining = true);

    try {
      await ref.read(groupControllerProvider).joinChannel(widget.channelId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined channel successfully!'),
            backgroundColor: AppColors.green500,
          ),
        );
        // Navigate to the chat
        context.go('/chat/${widget.channelId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join channel'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 24),

                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green500, width: 3),
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

                SizedBox(height: 16),

                // Channel Name
                Text(
                  channel.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black900,
                  ),
                ),

                SizedBox(height: 16),

                // Join Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinChannel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green500,
                        foregroundColor: AppColors.white900,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isJoining
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white900,
                              ),
                            )
                          : Text(
                              'Join the channel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Hobbies Section
                hobbiesAsync.when(
                  data: (hobbies) {
                    if (hobbies.isEmpty) return SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: hobbies.map((hobby) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green500.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.green500),
                                ),
                                child: Text(
                                  hobby,
                                  style: TextStyle(
                                    color: AppColors.green500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => SizedBox.shrink(),
                  error: (_, __) => SizedBox.shrink(),
                ),

                SizedBox(height: 24),

                // Member Count
                if (channel.memberCount != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppColors.gray400, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${channel.memberCount} members',
                          style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: 14,
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

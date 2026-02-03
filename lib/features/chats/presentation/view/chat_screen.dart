import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/services/presence_service.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
import 'package:lockmess/features/chats/presentation/widgets/chat_info_drawer.dart';
import 'package:lockmess/features/chats/presentation/widgets/group_chat_info_drawer.dart';
import 'package:lockmess/features/chats/presentation/widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachmentMenu = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider).markAsRead(widget.conversationId);
    });
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(chatControllerProvider)
        .sendMessage(widget.conversationId, content);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );

    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.green500,
                    size: 32,
                  ),
                  onPressed: () => context.pop(),
                ),

                // Avatar with green border
                conversationAsync.when(
                  data: (conversation) => Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.green500, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(
                        conversation?.displayAvatar.isNotEmpty == true
                            ? conversation!.displayAvatar
                            : 'https://github.com/shadcn.png',
                      ),
                    ),
                  ),
                  loading: () => CircleAvatar(radius: 22),
                  error: (_, __) => CircleAvatar(radius: 22),
                ),

                const SizedBox(width: 12),

                // Name and Online status
                Expanded(
                  child: conversationAsync.when(
                    data: (conversation) {
                      // Get other user's ID for presence check
                      final otherUserId = conversation?.otherUser?.id;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation?.displayName ?? 'Chat',
                            style: TextStyle(
                              color: AppColors.black900,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (otherUserId != null &&
                              conversation?.isDirect == true)
                            Consumer(
                              builder: (context, ref, _) {
                                final presenceAsync = ref.watch(
                                  userPresenceProvider(otherUserId),
                                );
                                return presenceAsync.when(
                                  data: (isOnline) => Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? AppColors.green500
                                              : AppColors.gray400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline
                                              ? AppColors.green500
                                              : AppColors.gray400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  loading: () => Text(
                                    'Connecting...',
                                    style: TextStyle(
                                      color: AppColors.gray400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: AppColors.gray400,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Text(
                              conversation?.isMultiUser == true
                                  ? '${conversation?.memberCount ?? 0} members'
                                  : 'Offline',
                              style: TextStyle(
                                color: AppColors.gray400,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => Text('Loading...'),
                    error: (_, __) => Text('Chat'),
                  ),
                ),

                // 3-dot menu
                Consumer(
                  builder: (context, ref, _) {
                    final conversation = ref
                        .watch(conversationProvider(widget.conversationId))
                        .value;
                    return IconButton(
                      icon: Icon(Icons.more_vert, color: AppColors.black900),
                      onPressed: conversation != null
                          ? () {
                              if (conversation.isDirect) {
                                showChatInfoDrawer(context, conversation);
                              } else {
                                showGroupChatInfoDrawer(context, conversation);
                              }
                            }
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages list
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: AppColors.gray400),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final conversation = conversationAsync.value;
                        final isGroupChat = conversation?.isMultiUser ?? false;
                        return MessageBubble(
                          message: message,
                          showAvatar: true,
                          isGroupChat: isGroupChat,
                        );
                      },
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),

              // Input bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(color: AppColors.white900),
                child: Row(
                  children: [
                    // X / Close button
                    GestureDetector(
                      onTap: _toggleAttachmentMenu,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _showAttachmentMenu
                              ? AppColors.gray400
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _showAttachmentMenu ? Icons.close : Icons.add,
                          color: _showAttachmentMenu
                              ? AppColors.white900
                              : AppColors.gray400,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type Message',
                            hintStyle: TextStyle(
                              color: AppColors.gray400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(fontSize: 14),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send button
                    GestureDetector(
                      onTap: _hasText ? _sendMessage : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? AppColors.green500
                              : AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: _hasText
                              ? AppColors.white900
                              : AppColors.gray400,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Attachment menu popup
          if (_showAttachmentMenu)
            Positioned(
              bottom: 70,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white900,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.attach_file,
                      label: 'Share a file',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.image_outlined,
                      label: 'Images',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentOption(
                      icon: Icons.mic_outlined,
                      label: 'Voices',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {
          _showAttachmentMenu = false;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gray400, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppColors.black900, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

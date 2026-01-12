import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Mark as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider).markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
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

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
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
      appBar: AppBar(
        backgroundColor: AppColors.white900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black900),
          onPressed: () => context.pop(),
        ),
        title: conversationAsync.when(
          data: (conversation) => Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(
                  conversation?.displayAvatar.isNotEmpty == true
                      ? conversation!.displayAvatar
                      : 'https://github.com/shadcn.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  conversation?.displayName ?? 'Chat',
                  style: TextStyle(
                    color: AppColors.black900,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => Row(
            children: [
              CircleAvatar(radius: 20),
              const SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppColors.black900,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              CircleAvatar(radius: 20),
              const SizedBox(width: 12),
              Text(
                'Chat',
                style: TextStyle(
                  color: AppColors.black900,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black900),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
      body: Column(
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

                // Scroll to bottom when messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showAvatar =
                        !message.isMine &&
                        (index == messages.length - 1 ||
                            messages[index + 1].senderId != message.senderId);

                    return MessageBubble(
                      message: message,
                      showAvatar: showAvatar,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white900,
              border: Border(
                top: BorderSide(color: AppColors.gray100, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.gray400,
                  ),
                  onPressed: () {
                    // Handle attachments
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'type message',
                      hintStyle: TextStyle(
                        color: AppColors.gray400,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.green500),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

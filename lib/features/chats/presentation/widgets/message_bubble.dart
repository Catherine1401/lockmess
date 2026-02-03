import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool isGroupChat;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.isGroupChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);
    final shouldShowAvatar = showAvatar && !message.isMine;
    final shouldShowName = isGroupChat && !message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: message.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender name for group chats (only for received messages)
          if (shouldShowName)
            Padding(
              padding: EdgeInsets.only(
                left: shouldShowAvatar ? 44 : 0,
                bottom: 4,
              ),
              child: Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: message.isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar for received messages
              if (shouldShowAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.gray200,
                    child: message.senderAvatar.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: message.senderAvatar,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.person,
                                size: 20,
                                color: AppColors.gray400,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 20,
                                color: AppColors.gray400,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                  ),
                ),
              // Message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isMine
                        ? AppColors
                              .green100 // Light green for sent
                        : AppColors.green400, // Green for received
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isMine
                          ? AppColors.black900
                          : AppColors.white900,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: message.isMine ? 0 : (shouldShowAvatar ? 44 : 8),
              right: message.isMine ? 8 : 0,
            ),
            child: Text(
              time,
              style: TextStyle(fontSize: 11, color: AppColors.gray400),
            ),
          ),
        ],
      ),
    );
  }
}

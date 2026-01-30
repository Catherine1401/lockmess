import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';

class ConversationSearchScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationName;

  const ConversationSearchScreen({
    super.key,
    required this.conversationId,
    required this.conversationName,
  });

  @override
  ConsumerState<ConversationSearchScreen> createState() =>
      _ConversationSearchScreenState();
}

class _ConversationSearchScreenState
    extends ConsumerState<ConversationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Message> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(List<Message> allMessages) {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    final results = allMessages.where((message) {
      return message.content.toLowerCase().contains(query);
    }).toList();

    // Sort by date, newest first
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: AppBar(
        backgroundColor: AppColors.white900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black900),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search',
          style: TextStyle(
            color: AppColors.black900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in "${widget.conversationName}"',
                  hintStyle: TextStyle(color: AppColors.gray400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.gray400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.gray400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  messagesAsync.whenData((messages) {
                    _performSearch(messages);
                  });
                },
              ),
            ),
          ),

          // Results count
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} found',
                    style: TextStyle(color: AppColors.gray400, fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Initial search when messages load
                if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _performSearch(messages);
                  });
                }

                if (_searchQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: AppColors.gray200),
                        const SizedBox(height: 16),
                        Text(
                          'Search for messages',
                          style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.gray200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages found',
                          style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final message = _searchResults[index];
                    return _buildSearchResultItem(message);
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
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Message message) {
    final time = DateFormat('MMM d, yyyy • HH:mm').format(message.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message.isMine ? 'You' : message.senderName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green500,
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: AppColors.gray400),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message content with highlighted search term
          _buildHighlightedText(message.content),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    if (_searchQuery.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 14, color: AppColors.black900),
      );
    }

    final query = _searchQuery.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(query, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: TextStyle(fontSize: 14, color: AppColors.black900),
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(fontSize: 14, color: AppColors.black900),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.green500,
            backgroundColor: AppColors.green100,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}

/// Shows the conversation search screen
void showConversationSearch(
  BuildContext context,
  String conversationId,
  String conversationName,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ConversationSearchScreen(
        conversationId: conversationId,
        conversationName: conversationName,
      ),
    ),
  );
}

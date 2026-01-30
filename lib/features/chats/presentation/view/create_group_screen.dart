import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/friends/presentation/viewmodel/friend_provider.dart';
import 'package:lockmess/features/chats/presentation/viewmodel/chat_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    print('🟡 [CreateGroupScreen] Create group button pressed');

    if (_groupNameController.text.trim().isEmpty) {
      print('🔴 [CreateGroupScreen] Validation failed: empty group name');
      _showError('Please enter group name');
      return;
    }

    if (_selectedFriendIds.isEmpty) {
      print('🔴 [CreateGroupScreen] Validation failed: no members selected');
      _showError('Please select at least one member');
      return;
    }

    print('🟡 [CreateGroupScreen] Validation passed');
    print(
      '🟡 [CreateGroupScreen] Group name: ${_groupNameController.text.trim()}',
    );
    print('🟡 [CreateGroupScreen] Selected members: $_selectedFriendIds');

    setState(() => _isCreating = true);

    try {
      print('🟡 [CreateGroupScreen] Calling createGroup...');
      final conversation = await ref
          .read(groupControllerProvider)
          .createGroup(
            name: _groupNameController.text.trim(),
            memberIds: _selectedFriendIds.toList(),
          );

      print('🟡 [CreateGroupScreen] Group created, navigating back');
      if (mounted) {
        context.pop(conversation);
      }
    } catch (e, stackTrace) {
      print('🔴 [CreateGroupScreen] Error: $e');
      print('🔴 [CreateGroupScreen] Stack trace: $stackTrace');
      _showError('Failed to create group: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
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

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: AppBar(
        backgroundColor: AppColors.green500,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white900),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Group',
              style: TextStyle(
                color: AppColors.white900,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Add members',
              style: TextStyle(
                color: AppColors.white900.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white900,
                    ),
                  )
                : Text(
                    'Next',
                    style: TextStyle(
                      color: AppColors.white900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group name section
          Container(
            color: AppColors.white900,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.gray400,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      hintText: 'Group Subject',
                      hintStyle: TextStyle(
                        color: AppColors.gray400,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.green500),
                      ),
                    ),
                    style: TextStyle(fontSize: 16, color: AppColors.black900),
                  ),
                ),
              ],
            ),
          ),

          // Selected members preview
          if (_selectedFriendIds.isNotEmpty)
            Container(
              color: AppColors.white900,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: friendsAsync.when(
                        data: (friends) {
                          final selectedFriends = friends
                              .where((f) => _selectedFriendIds.contains(f.id))
                              .toList();
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedFriends.length,
                            itemBuilder: (context, index) {
                              final friend = selectedFriends[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              friend.avatarUrl.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  friend.avatarUrl,
                                                )
                                              : null,
                                          child: friend.avatarUrl.isEmpty
                                              ? Text(friend.displayName[0])
                                              : null,
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedFriendIds.remove(
                                                  friend.id,
                                                );
                                              });
                                            },
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: AppColors.gray400,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 12,
                                                color: AppColors.white900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      friend.displayName.split(' ').first,
                                      style: TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => SizedBox(),
                        error: (_, __) => SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: AppColors.gray200),

          // Search bar
          Container(
            color: AppColors.white900,
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: AppColors.gray400),
                prefixIcon: Icon(Icons.search, color: AppColors.gray400),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Friends list
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
                    child: Text(
                      'No friends yet',
                      style: TextStyle(color: AppColors.gray400),
                    ),
                  );
                }

                final filteredFriends = friends.where((friend) {
                  if (_searchQuery.isEmpty) return true;
                  return friend.displayName.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      friend.username.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = filteredFriends[index];
                    final isSelected = _selectedFriendIds.contains(friend.id);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: friend.avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(friend.avatarUrl)
                            : null,
                        child: friend.avatarUrl.isEmpty
                            ? Text(friend.displayName[0])
                            : null,
                      ),
                      title: Text(
                        friend.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '@${friend.username}',
                        style: TextStyle(
                          color: AppColors.gray400,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedFriendIds.add(friend.id);
                            } else {
                              _selectedFriendIds.remove(friend.id);
                            }
                          });
                        },
                        activeColor: AppColors.green500,
                        shape: CircleBorder(),
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFriendIds.remove(friend.id);
                          } else {
                            _selectedFriendIds.add(friend.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading friends')),
            ),
          ),
        ],
      ),
    );
  }
}

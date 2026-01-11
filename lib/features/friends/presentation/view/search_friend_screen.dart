import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/friends/presentation/viewmodel/friend_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SearchFriendScreen extends ConsumerStatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  ConsumerState<SearchFriendScreen> createState() => _SearchFriendScreenState();
}

class _SearchFriendScreenState extends ConsumerState<SearchFriendScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _onSearch() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    final searchAsync = ref.watch(searchUsersProvider(query));

    return Scaffold(
      backgroundColor: AppColors.white900,
      appBar: AppBar(
        backgroundColor: AppColors.green500,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white900),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: AppColors.white900, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search by name...',
            hintStyle: TextStyle(
              color: AppColors.white900.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            border: InputBorder.none,
          ),
          onChanged: (_) => _onSearch(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: AppColors.white900),
              onPressed: () {
                _searchController.clear();
                _onSearch();
              },
            ),
        ],
      ),
      body: searchAsync.when(
        data: (users) {
          if (users.isEmpty && query.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No users found',
                  style: ShadTheme.of(
                    context,
                  ).textTheme.h4.copyWith(color: AppColors.gray400),
                ),
              ),
            );
          }
          if (query.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'Type to search users',
                  style: ShadTheme.of(
                    context,
                  ).textTheme.h4.copyWith(color: AppColors.gray400),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.gray100, indent: 76),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green500, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      user.avatarUrl.isNotEmpty
                          ? user.avatarUrl
                          : 'https://github.com/shadcn.png',
                    ),
                  ),
                ),
                title: Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black900,
                  ),
                ),
                subtitle: user.username.isNotEmpty
                    ? Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                      )
                    : null,
                onTap: () {
                  context.push('/user-profile', extra: user);
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Error: $e',
              style: ShadTheme.of(
                context,
              ).textTheme.h4.copyWith(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

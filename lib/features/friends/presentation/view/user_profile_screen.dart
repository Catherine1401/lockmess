import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/features/friends/presentation/viewmodel/friend_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class UserProfileScreen extends ConsumerWidget {
  final Profile profile;

  const UserProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar
                    _buildAvatar(profile.avatarUrl),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      profile.displayName,
                      style: ShadTheme.of(
                        context,
                      ).textTheme.custom['nameProfile'],
                    ),
                    const SizedBox(height: 4),

                    // Username with copy icon
                    _buildUsername(context, profile.username),
                    const SizedBox(height: 24),

                    // Action Buttons based on Friend Status
                    _buildActionButtons(context, ref, profile.id),
                    const SizedBox(height: 32),

                    // Profile Info Container
                    _buildProfileInfoContainer(context, profile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.black900),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.green500, width: 4),
      ),
      child: CircleAvatar(
        radius: 66,
        backgroundImage: CachedNetworkImageProvider(
          avatarUrl.isNotEmpty ? avatarUrl : 'https://github.com/shadcn.png',
        ),
      ),
    );
  }

  Widget _buildUsername(BuildContext context, String username) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ID: @$username',
          style: ShadTheme.of(context).textTheme.custom['usernameProfile'],
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: username));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Username copied'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Icon(Icons.content_copy, size: 16, color: AppColors.gray400),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String targetId,
  ) {
    final statusAsync = ref.watch(friendStatusProvider(targetId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: statusAsync.when(
        data: (status) {
          if (status == 'none') {
            // Stranger - Show "Add Friend" button
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(friendControllerProvider).sendRequest(targetId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green500,
                  foregroundColor: AppColors.white900,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add Friend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            );
          } else if (status == 'friend') {
            // Friend - Show "Unfriend" and "Message" buttons
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(friendControllerProvider).unfriend(targetId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white900,
                      foregroundColor: AppColors.black900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(color: AppColors.gray200, width: 1),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Unfriend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to chat
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green500,
                      foregroundColor: AppColors.white900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (status == 'sent') {
            // Sent request - Show "Cancel Request" button
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(friendControllerProvider).cancelRequest(targetId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray200,
                  foregroundColor: AppColors.black900,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Cancel Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            );
          } else if (status == 'received') {
            // Received request - Show "Decline" and "Accept" buttons
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(friendControllerProvider)
                          .declineRequest(targetId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: AppColors.white900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(friendControllerProvider)
                          .acceptRequest(targetId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green500,
                      foregroundColor: AppColors.white900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return SizedBox();
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (_, __) => SizedBox(),
      ),
    );
  }

  Widget _buildProfileInfoContainer(BuildContext context, Profile profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            'Phone',
            profile.phone.isNotEmpty ? profile.phone : '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Gender',
            profile.gender.isNotEmpty ? profile.gender : '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Birthday',
            profile.birthday.isNotEmpty ? profile.birthday : '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Email',
            profile.email.isNotEmpty ? profile.email : '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Hobby',
            profile.hobbies.isNotEmpty ? profile.hobbies.join(', ') : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label :',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.gray400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.black900,
            ),
          ),
        ),
      ],
    );
  }
}

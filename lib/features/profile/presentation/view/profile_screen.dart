import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/widgets/root_screen.dart';
import 'package:lockmess/features/profile/data/repositoties/profile_repository_impl.dart';
import 'package:lockmess/features/profile/domain/entities/profile.dart';
import 'package:lockmess/features/profile/presentation/viewmodel/profile_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileController = ref.watch(profileProvider);
    print('profile screen');
    return switch (profileController) {
      AsyncValue(hasError: true) => Text('Oops...'),
      AsyncValue(:final value, hasValue: true) => _buildProfile(
        value!,
        context,
        ref,
      ),
      _ => Center(child: CircularProgressIndicator.adaptive()),
    };
  }

  Widget _buildProfile(Profile profile, BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // action (edit)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white900,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                        color: AppColors.black800.withValues(alpha: .12),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/edit.svg',
                    width: 15,
                    height: 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        // info
        LayoutBuilder(
          builder: (_, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxWidth = constraints.maxWidth;
            return Align(
              alignment: Alignment.bottomCenter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: maxHeight * .8,
                    decoration: BoxDecoration(color: AppColors.green300),
                  ),

                  // info
                  Positioned(
                    top: -70,
                    child: SizedBox(
                      width: maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // avatqar
                          _buildAvatar(profile.avatarUrl),
                          const SizedBox(height: 12),

                          // display name
                          Text(
                            profile.displayName,
                            style: ShadTheme.of(
                              context,
                            ).textTheme.custom['nameProfile'],
                          ),
                          // const SizedBox(height: 2),

                          // username
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: @${profile.username}',
                                style: ShadTheme.of(
                                  context,
                                ).textTheme.custom['usernameProfile'],
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  child: SvgPicture.asset(
                                    'assets/icons/copy.svg',
                                    width: 14,
                                    height: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // phone
                          _buildItemProfile(
                            'Phone',
                            profile.phone.isNotEmpty ? profile.phone : '-',
                            context,
                          ),
                          const SizedBox(height: 10),

                          // gender
                          _buildItemProfile(
                            'Gender',
                            profile.gender.isNotEmpty ? profile.gender : '-',
                            context,
                          ),
                          const SizedBox(height: 10),

                          // birthday
                          _buildItemProfile(
                            'Birthday',
                            profile.birthday.isNotEmpty
                                ? profile.birthday
                                : '-',
                            context,
                          ),
                          const SizedBox(height: 10),

                          // email
                          _buildItemProfile(
                            'Email',
                            profile.email.isNotEmpty ? profile.email : '-',
                            context,
                          ),
                          const SizedBox(height: 10),

                          // hobbies
                          _buildHobby('Hobby', profile.hobbies, context),
                          const SizedBox(height: 30),

                          // logout
                          _buildLogout(context, ref),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: BoxBorder.all(width: 2, color: AppColors.green600),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
        ),

        // action
        Positioned(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white900,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset('assets/icons/haflcircle.svg'),
                    SvgPicture.asset('assets/icons/circle.svg'),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: SvgPicture.asset('assets/icons/plus.svg'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemProfile(String title, String content, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style: ShadTheme.of(context).textTheme.custom['titleProfile'],
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: ShadTheme.of(context).textTheme.custom['contentProfile'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHobby(String title, List<String> hobbies, BuildContext context) {
    print('day la hobbies: $hobbies');
    final hobbiesString = hobbies.isNotEmpty ? hobbies.join(', ') : '-';
    print(hobbies.isNotEmpty);
    print(hobbies.length);
    print(hobbiesString);
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: ShadTheme.of(context).textTheme.custom['titleProfile'],
            ),
          ),
          Expanded(
            child: Text(
              hobbiesString,
              style: ShadTheme.of(context).textTheme.custom['contentProfile'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return ShadButton(
      gap: 16, 
      backgroundColor: AppColors.green450,
      padding: EdgeInsets.symmetric(horizontal: 42),
      onPressed: () {
        ref.read(profileRepositoryProvider).logout();
        ref.read(bottomNavProvider.notifier).changeTab(0);
      },
      decoration: ShadDecoration(
        border: ShadBorder.all(radius: BorderRadius.circular(20)),
        shadows: <BoxShadow>[
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
            color: AppColors.black900.withValues(alpha: .25),
          ),
        ],
      ),
      leading: SvgPicture.asset(
        'assets/icons/logout.svg',
        width: 24,
        height: 24,
      ),
      child: Text(
        'Logout',
        style: ShadTheme.of(context).textTheme.custom['logoutProfile'],
      ),
    );
  }
}

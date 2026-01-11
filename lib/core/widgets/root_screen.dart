import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

final bottomNavProvider = NotifierProvider<BottomNavNotifier, int>(() {
  return BottomNavNotifier();
});

class BottomNavNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void changeTab(int index) {
    state = index;
  }
}

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 84,
        padding: EdgeInsets.only(top: 13),
        decoration: BoxDecoration(
          color: AppColors.white900,
          borderRadius: BorderRadiusGeometry.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              offset: Offset(0, 0),
              blurRadius: 4,
              spreadRadius: 0,
              color: AppColors.black900.withValues(alpha: .3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemNavBar('assets/icons/chat.svg', 'Chats', 0, context, ref),
            _buildItemNavBar(
              'assets/icons/group.svg',
              'Groups',
              1,
              context,
              ref,
            ),
            _buildItemNavBar(
              'assets/icons/profile.svg',
              'Profile',
              2,
              context,
              ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemNavBar(
    String icon,
    String label,
    int index,
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentIndex = ref.watch(bottomNavProvider);
    // final currentIndex = navigationShell.currentIndex;
    return Expanded(
      child: Material(
        child: InkResponse(
          onTap: () {
            navigationShell.goBranch(index);
            ref.read(bottomNavProvider.notifier).changeTab(index);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  currentIndex == index
                      ? AppColors.green350
                      : AppColors.black200,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: ShadTheme.of(context).textTheme.custom['labelBottomNav']!
                    .copyWith(
                      color: index == currentIndex
                          ? AppColors.green350
                          : AppColors.black200,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: GradientText(
        'Lockmess',
        colors: [AppColors.green700, AppColors.green400],
        style: ShadTheme.of(context).textTheme.custom['titleAppbar'],
      ),
      actions: <Widget>[
        // add frind
        Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: () {
              context.push('/friend');
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icons/friend.svg',
                    colorFilter: ColorFilter.mode(
                      AppColors.green500,
                      BlendMode.srcIn,
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: SvgPicture.asset(
                      'assets/icons/plus.svg',
                      colorFilter: ColorFilter.mode(
                        AppColors.green500,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 28),
        // three dot
        Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: () {},
            radius: 60,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/dot.svg',
                      colorFilter: ColorFilter.mode(
                        AppColors.green500,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SvgPicture.asset(
                      'assets/icons/dot.svg',
                      colorFilter: ColorFilter.mode(
                        AppColors.green500,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SvgPicture.asset(
                      'assets/icons/dot.svg',
                      colorFilter: ColorFilter.mode(
                        AppColors.green500,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.only(right: 22),
    );
  }
}

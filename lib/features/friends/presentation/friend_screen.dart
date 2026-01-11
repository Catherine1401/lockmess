import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FriendScreen extends ConsumerWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          MultiSliver(
            children: [
              const SizedBox(height: 24),
              _buildX(context),
              _buildQuantityFriends(context, ref),
              const SizedBox(height: 16),
              _buildSearchBar(context),
              const SizedBox(height: 16),
              _buildLabelFriends(
                context,
                'assets/icons/search.svg',
                'Find friends from other apps',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildX(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: () {
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white900,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    spreadRadius: 0,
                    color: AppColors.gray500,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/icons/x.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  AppColors.black900,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildQuantityFriends(BuildContext context, WidgetRef ref) {
    return Text(
      '20 friends',
      textAlign: TextAlign.center,
      style: ShadTheme.of(context).textTheme.custom['quantityFrinds'],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.green500,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // text
              Expanded(
                child: Text(
                  'Make a new friend',
                  style: ShadTheme.of(context).textTheme.custom['inSearch'],
                ),
              ),

              // icon
              SvgPicture.asset(
                'assets/icons/search.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  AppColors.white900,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelFriends(BuildContext context, String icon, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(AppColors.gray200, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Text(
            content,
            style: ShadTheme.of(
              context,
            ).textTheme.custom['inSearch']!.copyWith(color: AppColors.gray200),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerLink(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100.withValues(alpha: .75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [],
      ),
    );
  }

  Widget _buildLink(BuildContext context) {

  }
}

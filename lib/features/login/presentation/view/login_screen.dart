import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/features/login/data/repositories/login_repository_imp.dart';
import 'package:lockmess/features/login/presentation/widgets/form_login.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // logo
          Row(
            children: [
              GradientText(
                'LockMess',
                style: ShadTheme.of(context).textTheme.h1Large,
                colors: [AppColors.green700, AppColors.green400],
              ),
            ],
          ),
          const SizedBox(height: 54),
          // hello
          Row(
            children: [
              Text(
                'Hi friend!',
                style: ShadTheme.of(context).textTheme.h2,
                textAlign: TextAlign.start,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                'Enter you email to sign in',
                style: ShadTheme.of(context).textTheme.h3,
              ),
            ],
          ),
          const SizedBox(height: 45),
          // form
          FormLogin(),
          const SizedBox(height: 53),
          // other options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.black200, height: 1)),
                const SizedBox(width: 9),
                Text(
                  'or continue with',
                  style: ShadTheme.of(context).textTheme.h4.copyWith(
                    color: AppColors.black900,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(child: Divider(color: AppColors.black200, height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShadButton.outline(
                backgroundColor: Colors.transparent,
                decoration: ShadDecoration(
                  shape: BoxShape.circle,
                  border: ShadBorder.all(color: AppColors.black200, width: 1),
                ),
                onPressed: () async {
                  final loginProvider = ref.read(loginRepositoryProvider);
                  final user = await loginProvider.signInWithGoogle();
                  print(user.email);
                },
                child: SvgPicture.asset(
                  'assets/icons/google.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 16),
              ShadButton.outline(
                // backgroundColor: Colors.transparent,
                onPressed: () {},
                decoration: ShadDecoration(
                  shape: BoxShape.circle,
                  border: ShadBorder.all(color: AppColors.black200, width: 1),
                ),
                child: SvgPicture.asset(
                  'assets/icons/apple.svg',
                  colorFilter: ColorFilter.mode(
                    AppColors.black900,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

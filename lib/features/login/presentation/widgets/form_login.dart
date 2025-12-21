import 'package:flutter/material.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FormLogin extends StatefulWidget {
  const FormLogin({super.key});

  @override
  State<FormLogin> createState() => _FormLoginState();
}

class _FormLoginState extends State<FormLogin> {
  final _formKey = GlobalKey<ShadFormState>();

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInputFormField(
            id: 'email',
            placeholder: Text(
              'Enter your email',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            padding: const EdgeInsetsGeometry.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: ShadDecoration(
              // canMerge: false,
              shadows: [
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 0,
                  spreadRadius: 0,
                  color: AppColors.purple400.withValues(alpha: 42),
                ),
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 1,
                  spreadRadius: 0,
                  color: AppColors.gray500.withValues(alpha: 47),
                ),
              ],
              color: AppColors.green300,
              border: ShadBorder.all(
                width: 0,
                radius: BorderRadiusGeometry.circular(55),
              ),
              focusedBorder: ShadBorder.all(
                width: 0,
                radius: BorderRadiusGeometry.circular(55),
              ),
              errorBorder: ShadBorder.none,
              secondaryFocusedBorder: ShadBorder.none,
            ),
          ),
          const SizedBox(height: 31),
          // password
          ShadInputFormField(
            id: 'password',
            keyboardType: TextInputType.visiblePassword,
            placeholder: Text(
              'Enter your password',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            padding: const EdgeInsetsGeometry.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: ShadDecoration(
              // canMerge: false,
              shadows: [
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 0,
                  spreadRadius: 0,
                  color: AppColors.purple400.withValues(alpha: 42),
                ),
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 1,
                  spreadRadius: 0,
                  color: AppColors.gray500.withValues(alpha: 47),
                ),
              ],
              color: AppColors.green300,
              border: ShadBorder.all(
                width: 0,
                radius: BorderRadiusGeometry.circular(55),
              ),
              focusedBorder: ShadBorder.all(
                width: 0,
                radius: BorderRadiusGeometry.circular(55),
              ),
              errorBorder: ShadBorder.none,
              secondaryFocusedBorder: ShadBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          // forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Forgot password',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 29),
          // submit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShadButton(
              height: 40,
              onPressed: () {},
              gradient: LinearGradient(
                colors: [AppColors.green700, AppColors.green400],
              ),
              decoration: ShadDecoration(
                border: ShadBorder.all(
                  radius: BorderRadiusGeometry.circular(50),
                ),
              ),
              child: Text(
                'Continue',
                style: ShadTheme.of(context).textTheme.h2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

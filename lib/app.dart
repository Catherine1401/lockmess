import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return ShadApp.router(
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        textTheme: ShadTextTheme(
          custom: {
            'labelBottomNav': GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              letterSpacing: 0,
            ),
            'titleAppbar': GoogleFonts.roboto(
              fontWeight: FontWeight.w700,
              fontSize: 32,
            ),
            'nameProfile': GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: AppColors.black900,
            ),
            'usernameProfile': GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.gray400,
            ),
            'titleProfile': GoogleFonts.roboto(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: AppColors.gray300,
            ),
            'contentProfile': GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: AppColors.black900,
            ),
            'logoutProfile': GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: AppColors.black900,
            ),
          },
          h1Large: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            fontSize: 50,
            // height: 42 / 64,
            letterSpacing: -.41,
          ),
          h2: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: AppColors.black900,
          ),
          h3: GoogleFonts.roboto(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            color: AppColors.black900,
          ),
          h4: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: AppColors.black200,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

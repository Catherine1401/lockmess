import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lockmess/core/theme/colors.dart';
import 'package:lockmess/router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        textTheme: ShadTextTheme(
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

import 'package:flutter/material.dart';
import 'package:lockmess/router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

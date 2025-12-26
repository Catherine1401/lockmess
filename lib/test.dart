import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/features/profile/data/repositoties/profile_repository_impl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class Test extends ConsumerWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadButton(
      onPressed: () {
        ref.read(profileRepositoryProvider).logout();
      },
      child: Text('log out'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/constants/colors.dart';
import 'package:lockmess/core/network/supabase.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Settings list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Language
                    _buildLanguageRow(),
                    const SizedBox(height: 24),

                    // Dark Mode
                    _buildSwitchRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      value: _isDarkMode,
                      onChanged: (val) => setState(() => _isDarkMode = val),
                    ),
                    const SizedBox(height: 24),

                    // Mute Notification
                    _buildSwitchRow(
                      icon: Icons.volume_off_outlined,
                      label: 'Mute Notification',
                      value: _isMuted,
                      onChanged: (val) => setState(() => _isMuted = val),
                    ),
                    const SizedBox(height: 24),

                    // Custom Notification
                    _buildNavigationRow(
                      icon: Icons.notifications_outlined,
                      label: 'Custom Notification',
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),

                    // Invite Friends
                    _buildNavigationRow(
                      icon: Icons.person_add_outlined,
                      label: 'Invite Friends',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Joined Channel
                    _buildNavigationRow(
                      icon: Icons.groups_outlined,
                      label: 'Joined Channel',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Security
                    _buildNavigationRow(
                      icon: Icons.security_outlined,
                      label: 'Security',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // About App
                    _buildNavigationRow(
                      icon: Icons.info_outlined,
                      label: 'About App',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Help Center
                    _buildNavigationRow(
                      icon: Icons.help_outline,
                      label: 'Help Center',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Logout
                    _buildLogoutRow(context),
                    const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.more_vert, color: AppColors.black900, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow() {
    return Row(
      children: [
        Icon(Icons.translate, color: AppColors.gray400, size: 22),
        const SizedBox(width: 16),
        Text(
          'Language',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.black900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.black900,
            ),
            style: TextStyle(fontSize: 14, color: AppColors.black900),
            items: ['English', 'Vietnamese', 'Spanish', 'French']
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedLanguage = val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gray400, size: 22),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.black900,
          ),
        ),
        const Spacer(),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.white900;
              }
              return AppColors.white900;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.green400;
              }
              return AppColors.gray200;
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray400, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.black900,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.gray400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutRow(BuildContext context) {
    return InkWell(
      onTap: () async {
        final supabaseClient = ref.read(supabase).client;
        await supabaseClient.auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pop();
          context.go('/');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.logout, color: AppColors.green500, size: 22),
            const SizedBox(width: 16),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.green500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the settings screen as a right-side drawer (7/8 of screen width)
void showSettingsDrawer(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: screenWidth * 7 / 8,
            decoration: BoxDecoration(
              color: AppColors.white900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: const SettingsScreen(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}

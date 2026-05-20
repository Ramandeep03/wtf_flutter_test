import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class RoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String roleName;
  final Color primaryColor;
  final List<Widget>? actions;
  final VoidCallback? onLogout;

  const RoleAppBar({
    super.key,
    required this.userName,
    required this.roleName,
    required this.primaryColor,
    this.actions,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) => AppBar(
        title: const Text('WTF Fitness'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$roleName • $userName',
                style: AppTypography.label.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (onLogout != null)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: onLogout,
            ),
          ...?actions,
        ],
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

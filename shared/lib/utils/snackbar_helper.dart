import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

class SnackbarHelper {
  static void showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: AppColors.error,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      action: SnackBarAction(
        label: 'Copy',
        textColor: Colors.white70,
        onPressed: () => Clipboard.setData(ClipboardData(text: msg)),
      ),
    ));
  }

  static void showSuccess(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  static void showInfo(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

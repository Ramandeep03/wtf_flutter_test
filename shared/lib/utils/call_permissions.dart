import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'snackbar_helper.dart';

/// Requests mic + camera permissions, then navigates to `/pre-join`.
/// Shows an error snackbar and does nothing if either is denied.
Future<void> requestCallAndNavigate(
  BuildContext ctx, {
  required String callRequestId,
  required String role,
}) async {
  final mic = await Permission.microphone.request();
  final cam = await Permission.camera.request();
  if (!mic.isGranted || !cam.isGranted) {
    if (ctx.mounted) {
      SnackbarHelper.showError(ctx, 'Camera and mic permissions required');
    }
    return;
  }
  if (!ctx.mounted) return;
  ctx.push('/pre-join?callRequestId=$callRequestId&role=$role');
}

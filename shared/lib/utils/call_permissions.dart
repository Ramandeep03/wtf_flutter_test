import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'snackbar_helper.dart';

/// Requests mic + camera permissions, then navigates to `/pre-join`.
/// Pass `memberId` and `trainerId` from the call request so the
/// downstream `/post-call` flow can write the correct `session_logs` doc.
Future<void> requestCallAndNavigate(
  BuildContext ctx, {
  required String callRequestId,
  required String role,
  required String memberId,
  required String trainerId,
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
  ctx.push(
    '/pre-join?callRequestId=$callRequestId'
    '&role=$role'
    '&memberId=$memberId'
    '&trainerId=$trainerId',
  );
}

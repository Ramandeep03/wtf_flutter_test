/// Never log sensitive values in plain text — use these helpers at every
/// `AppLogger` call site that touches tokens, ids, emails, or URLs with
/// query params.
class LogMask {
  /// Last 4 chars: `eyJhb...x9kQ` → `****x9kQ`.
  static String token(String? value) {
    if (value == null || value.length < 5) return '****';
    return '****${value.substring(value.length - 4)}';
  }

  /// First 3 + last 3: `Xk29aBcdef` → `Xk2***def`.
  static String uid(String? value) {
    if (value == null || value.length < 7) return '***';
    return '${value.substring(0, 3)}***${value.substring(value.length - 3)}';
  }

  /// Always `****` — for passwords, API secrets, full tokens.
  static String secret(String? value) => '****';

  /// `dk@wtf.fit` → `**@wtf.fit`.
  static String email(String? value) {
    if (value == null) return '****';
    final parts = value.split('@');
    if (parts.length != 2) return '****';
    return '**@${parts[1]}';
  }

  /// `GET /hms-token?roomId=abc&role=member` → `GET /hms-token [params hidden]`.
  static String url(String method, String path) {
    final clean = path.contains('?')
        ? '${path.split('?').first} [params hidden]'
        : path;
    return '$method $clean';
  }
}

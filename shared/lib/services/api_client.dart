import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/log_mask.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  // Strip a trailing slash so '${_base}/health' doesn't become '…dev//health'
  // when the user pastes a base URL like https://….ngrok-free.dev/ .
  final String _base = AppConstants.backendBaseUrl.endsWith('/')
      ? AppConstants.backendBaseUrl
          .substring(0, AppConstants.backendBaseUrl.length - 1)
      : AppConstants.backendBaseUrl;

  String? get _token => Hive.box('app_prefs').get('id_token') as String?;

  // No logging in this getter — it would print the raw idToken.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // Skip the ngrok free-tier "you're about to visit" interstitial.
        // Harmless to send to non-ngrok backends — they ignore unknown headers.
        'ngrok-skip-browser-warning': 'true',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    AppLogger.t(LogTag.api, LogMask.url('GET', path));
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    return _handle(res);
  }

  /// For endpoints that return a JSON array (e.g. `/users`,
  /// `/call-requests?memberId=…`, `/session-logs?userId=…`).
  Future<List<dynamic>> getList(String path) async {
    AppLogger.t(LogTag.api, LogMask.url('GET', path));
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return body;
      throw ApiException(res.statusCode, 'Expected JSON array, got ${body.runtimeType}');
    }
    final msg = body is Map ? (body['error']?.toString() ?? 'Unknown error') : 'Unknown error';
    AppLogger.e(LogTag.api, 'HTTP ${res.statusCode} ${LogMask.url('GET', path)} — $msg');
    throw ApiException(res.statusCode, msg);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    AppLogger.t(LogTag.api, LogMask.url('POST', path));
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    AppLogger.t(LogTag.api, LogMask.url('PATCH', path));
    final res = await http.patch(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final method = res.request?.method ?? '?';
    final path   = res.request?.url.path ?? '?';
    final masked = LogMask.url(method, path);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = body['error']?.toString() ?? 'Unknown error';
    AppLogger.e(LogTag.api, 'HTTP ${res.statusCode} $masked — $msg');
    throw ApiException(res.statusCode, msg);
  }

  static Future<void> saveToken(String token) async {
    await Hive.box('app_prefs').put('id_token', token);
    AppLogger.i(LogTag.auth, 'idToken stored: ${LogMask.token(token)}');
  }

  static Future<void> clearToken() async {
    await Hive.box('app_prefs').delete('id_token');
    AppLogger.i(LogTag.auth, 'idToken cleared');
  }

  static String? get storedToken =>
      Hive.box('app_prefs').get('id_token') as String?;
}

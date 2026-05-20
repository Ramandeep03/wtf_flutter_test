import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

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

  final _base = AppConstants.backendBaseUrl;

  String? get _token => Hive.box('app_prefs').get('id_token') as String?;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    return _handle(res);
  }

  /// For endpoints that return a JSON array (e.g. `/users`,
  /// `/call-requests?memberId=…`, `/session-logs?userId=…`).
  Future<List<dynamic>> getList(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return body;
      throw ApiException(res.statusCode, 'Expected JSON array, got ${body.runtimeType}');
    }
    final msg = body is Map ? (body['error']?.toString() ?? 'Unknown error') : 'Unknown error';
    throw ApiException(res.statusCode, msg);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
      res.statusCode,
      body['error']?.toString() ?? 'Unknown error',
    );
  }

  static Future<void> saveToken(String token) async =>
      Hive.box('app_prefs').put('id_token', token);

  static Future<void> clearToken() async =>
      Hive.box('app_prefs').delete('id_token');

  static String? get storedToken =>
      Hive.box('app_prefs').get('id_token') as String?;
}

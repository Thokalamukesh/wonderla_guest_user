import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'cms_http_client.dart';

final _httpClient = createCmsHttpClient();

/// Flutter client for the existing Next.js QR admin API. Set API_BASE_URL for
/// native builds, e.g. https://your-domain.com. Web defaults to current host.
class CmsApi {
  CmsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _configuredBaseUrl();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String _configuredBaseUrl() {
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:3000';
      }
      // Keep browser API requests same-origin; Vercel proxies them to the CMS.
      return Uri.base.origin;
    }
    return _definedBaseUrl;
  }

  String _baseUrl;
  String? _cookie;
  String get baseUrl => _baseUrl;
  set baseUrl(String value) =>
      _baseUrl = value.trim().replaceAll(RegExp(r'/$'), '');
  bool get isConfigured => _baseUrl.isNotEmpty;
  Uri _uri(String path) => Uri.parse('$_baseUrl/qr-code/api$path');
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Cookie': ?_cookie,
  };

  Future<Map<String, dynamic>> _json(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final headers = {
      ..._headers,
      if (body != null) 'Content-Type': 'application/json',
    };
    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await _httpClient.send(request);
    final result = await http.Response.fromStream(response);
    final data = result.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(result.body) as Map<String, dynamic>;
    _saveCookie(result.headers);
    if (result.statusCode < 200 ||
        result.statusCode >= 300 ||
        data['ok'] == false) {
      throw CmsApiException(
        data['error']?.toString() ?? 'Request failed (${result.statusCode}).',
      );
    }
    return data;
  }

  void _saveCookie(Map<String, String> headers) {
    if (kIsWeb) {
      return; // Browser sends its HttpOnly same-origin cookie automatically.
    }
    final value = headers['set-cookie'];
    if (value == null) return;
    final pair = value.split(';').first;
    if (pair.startsWith('qr_admin_session=')) _cookie = pair;
  }

  Future<Map<String, dynamic>> login(String username, String password) async =>
      (await _json(
            '/auth/login',
            method: 'POST',
            body: {'username': username, 'password': password},
          ))['user']
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> session() async => _json('/auth/session');
  Future<void> logout() async {
    await _json('/auth/logout', method: 'POST');
    _cookie = null;
  }

  Future<List<Map<String, dynamic>>> parks() async =>
      List<Map<String, dynamic>>.from((await _json('/parks'))['parks'] as List);
  Future<Map<String, dynamic>> park(String slug) async =>
      (await _json('/parks/${Uri.encodeComponent(slug)}'))['config']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> savePark(
    String slug,
    Map<String, dynamic> config,
  ) async =>
      (await _json(
            '/parks/${Uri.encodeComponent(slug)}',
            method: 'PUT',
            body: config,
          ))['config']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> createPark(String name, String location) async =>
      (await _json(
            '/parks',
            method: 'POST',
            body: {'name': name, 'location': location},
          ))['park']
          as Map<String, dynamic>;
  Future<void> deletePark(String slug) async {
    await _json('/parks/${Uri.encodeComponent(slug)}', method: 'DELETE');
  }

  Future<List<Map<String, dynamic>>> users() async =>
      List<Map<String, dynamic>>.from((await _json('/users'))['users'] as List);
  Future<void> createUser(Map<String, dynamic> user) async {
    await _json('/users', method: 'POST', body: user);
  }

  Future<void> deleteUser(String username) async {
    await _json('/users/${Uri.encodeComponent(username)}', method: 'DELETE');
  }

  Future<Map<String, dynamic>> mapSettings() async => _json('/map-settings');
  Future<void> saveMapSettings(String apiKey) async {
    await _json('/map-settings', method: 'PUT', body: {'apiKey': apiKey});
  }

  Future<Map<String, dynamic>> siteUrl() async => _json('/site-url');

  Future<String> uploadImage(String parkSlug, XFile file) async {
    final name = file.name.toLowerCase();
    final type = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : name.endsWith('.gif')
        ? 'image/gif'
        : 'image/jpeg';
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const CmsApiException('Choose an image under 5 MB.');
    }
    final request =
        http.MultipartRequest(
            'POST',
            _uri('/parks/${Uri.encodeComponent(parkSlug)}/images'),
          )
          ..headers.addAll(_headers)
          ..files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: file.name,
              contentType: MediaType.parse(type),
            ),
          );
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw CmsApiException(
        data['error']?.toString() ??
            'Image upload failed (${response.statusCode}).',
      );
    }
    return data['url'] as String;
  }
}

class CmsApiException implements Exception {
  const CmsApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

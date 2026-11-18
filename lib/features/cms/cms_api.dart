import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'cms_http_client.dart';
import 'fallback_parks_data.dart';

final _httpClient = createCmsHttpClient();

/// Flutter client for the existing Next.js QR admin API. Set API_BASE_URL to
/// the backend origin when it is not available on the current web host.
class CmsApi {
  CmsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _configuredBaseUrl();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _defaultBackendOrigin =
      'https://wonderla-qr-project.vercel.app';

  static String _configuredBaseUrl() {
    final override = _definedBaseUrl.trim();
    if (override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:3000';
      }
      // Production deployments can serve the API from the same origin (or via Vercel rewrites).
      return Uri.base.origin;
    }
    return _defaultBackendOrigin;
  }

  String _baseUrl;
  String? _cookie;
  String get baseUrl => _baseUrl;
  set baseUrl(String value) =>
      _baseUrl = value.trim().replaceAll(RegExp(r'/$'), '');
  bool get isConfigured => _baseUrl.isNotEmpty;
  Uri _uri(String path, {String? baseOverride}) =>
      Uri.parse('${baseOverride ?? _baseUrl}/qr-code/api$path');
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
    http.Response result = await _sendJsonRequest(
      path,
      method: method,
      headers: headers,
      body: body,
    );
    if (_looksLikeHtmlFallback(result) &&
        _baseUrl != _defaultBackendOrigin &&
        _definedBaseUrl.trim().isEmpty) {
      _baseUrl = _defaultBackendOrigin;
      result = await _sendJsonRequest(
        path,
        method: method,
        headers: headers,
        body: body,
      );
    }
    final data = _decodeJson(result);
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

  Future<http.Response> _sendJsonRequest(
    String path, {
    required String method,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await _httpClient.send(request);
    return http.Response.fromStream(response);
  }

  bool _looksLikeHtmlFallback(http.Response response) =>
      response.body.trimLeft().startsWith('<');

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      if (_looksLikeHtmlFallback(response)) {
        throw CmsApiException(
          'Received an HTML response instead of JSON from ${response.request?.url ?? _baseUrl} (${response.statusCode}). Check your Vercel rewrites or API_BASE_URL.',
        );
      }
      rethrow;
    }
    throw CmsApiException(
      'Unexpected response format (${response.statusCode}).',
    );
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

  Future<List<Map<String, dynamic>>> parks() async {
    try {
      final list = List<Map<String, dynamic>>.from(
        (await _json('/parks'))['parks'] as List,
      );
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fall back to embedded park list when the backend is unavailable or unseeded.
    }
    return FallbackParksData.listParks();
  }

  Future<Map<String, dynamic>> park(String slug) async {
    try {
      return (await _json('/parks/${Uri.encodeComponent(slug)}'))['config']
          as Map<String, dynamic>;
    } catch (_) {
      final fallback = FallbackParksData.getPark(slug);
      if (fallback != null) return fallback;
      rethrow;
    }
  }
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

  Future<void> updateUserPermissions(
    String username,
    List<String> permissions,
  ) async {
    await _json(
      '/users/${Uri.encodeComponent(username)}',
      method: 'PATCH',
      body: {'permissions': permissions},
    );
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
    return _uploadMedia(
      parkSlug,
      file,
      path: 'images',
      field: 'image',
      type: type,
      maxBytes: 5 * 1024 * 1024,
      limitLabel: 'Choose an image under 5 MB.',
    );
  }

  Future<String> uploadVideo(String parkSlug, XFile file) {
    final name = file.name.toLowerCase();
    final type = name.endsWith('.webm')
        ? 'video/webm'
        : name.endsWith('.mov')
        ? 'video/quicktime'
        : 'video/mp4';
    return _uploadMedia(
      parkSlug,
      file,
      path: 'videos',
      field: 'video',
      type: type,
      maxBytes: 50 * 1024 * 1024,
      limitLabel: 'Choose a video under 50 MB.',
    );
  }

  Future<String> _uploadMedia(
    String parkSlug,
    XFile file, {
    required String path,
    required String field,
    required String type,
    required int maxBytes,
    required String limitLabel,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw CmsApiException(limitLabel);
    }
    final request =
        http.MultipartRequest(
            'POST',
            _uri('/parks/${Uri.encodeComponent(parkSlug)}/$path'),
          )
          ..headers.addAll(_headers)
          ..files.add(
            http.MultipartFile.fromBytes(
              field,
              bytes,
              filename: file.name,
              contentType: MediaType.parse(type),
            ),
          );
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final data = _decodeJson(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      final fallbackError = path == 'videos' && response.statusCode == 404
          ? 'Video uploads are not enabled on the connected CMS server yet.'
          : 'Media upload failed (${response.statusCode}).';
      throw CmsApiException(data['error']?.toString() ?? fallbackError);
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

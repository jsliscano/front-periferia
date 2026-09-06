import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/session_store.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP compartido para llamadas al backend.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool auth = false,
  }) async {
    return _requestMap(
      method: 'POST',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    return _requestMap(
      method: 'PUT',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    return _requestMap(
      method: 'GET',
      path: path,
      query: query,
      auth: auth,
    );
  }

  Future<void> delete(
    String path, {
    bool auth = true,
  }) async {
    await _send(
      method: 'DELETE',
      path: path,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> _requestMap({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final response = await _send(
      method: method,
      path: path,
      body: body,
      query: query,
      auth: auth,
    );

    final decoded = _decodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = false,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    late final http.Response response;
    try {
      final headers = _headers(auth: auth);
      final encodedBody = body == null ? null : jsonEncode(body);

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 15));
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 15));
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
        default:
          throw ApiException('Método HTTP no soportado: $method');
      }
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(
        'No se pudo conectar con el servidor. Verifica que el backend esté en ejecución.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final decoded = _decodeBody(response.body);
    throw ApiException(
      _extractErrorMessage(decoded, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  Map<String, String> _headers({required bool auth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final session = SessionStore.current;
      if (session == null) {
        throw const ApiException(
          'Sesión no encontrada. Inicia sesión nuevamente.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = session.authorizationHeader;
    }

    return headers;
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final message =
          decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (message != null) {
        return message.toString();
      }
    }
    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'No autorizado. Inicia sesión nuevamente.';
    }
    return 'Error del servidor ($statusCode)';
  }
}

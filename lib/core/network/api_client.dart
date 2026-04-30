import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.connectTimeout = ApiConfig.connectTimeout,
    this.receiveTimeout = ApiConfig.receiveTimeout,
    this.onUnauthorized,
    this.isOffline,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Future<void> Function()? onUnauthorized;
  final bool Function()? isOffline;
  final http.Client _httpClient;

  Future<dynamic> get(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
    bool handleUnauthorized = false,
  }) {
    return _send(
      method: 'GET',
      path: path,
      accessToken: accessToken,
      queryParameters: queryParameters,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<ApiBinaryResponse> getBytes(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
    bool handleUnauthorized = false,
  }) async {
    _throwIfOffline();

    final request = _buildRequest(
      method: 'GET',
      path: path,
      accessToken: accessToken,
      queryParameters: queryParameters,
    );

    try {
      final response = await _sendRequest(request);
      final decodedBody = _decodeResponseBody(response.bodyBytes);

      if (response.statusCode == 401 && handleUnauthorized) {
        await onUnauthorized?.call();
        throw const ApiException(
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
          statusCode: 401,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            _extractErrorMessage(decodedBody) ??
            'فشل تحميل الملف. رمز الحالة: ${response.statusCode}.';
        throw ApiException(message, statusCode: response.statusCode);
      }

      return ApiBinaryResponse(
        bytes: Uint8List.fromList(response.bodyBytes),
        fileName: _extractFileName(response.headers),
        contentType: response.headers['content-type'],
      );
    } on TimeoutException {
      throw const ApiException(
        'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة أو عنوان الـ API ثم حاول مرة أخرى.',
      );
    } on http.ClientException {
      throw const ApiException(
        'تعذر الوصول إلى خادم Laravel. تحقق من عنوان الـ API والاتصال ثم حاول مرة أخرى.',
      );
    }
  }

  Future<dynamic> post(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool handleUnauthorized = false,
  }) {
    return _send(
      method: 'POST',
      path: path,
      accessToken: accessToken,
      body: body,
      queryParameters: queryParameters,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<dynamic> patch(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool handleUnauthorized = false,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      accessToken: accessToken,
      body: body,
      queryParameters: queryParameters,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<dynamic> delete(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool handleUnauthorized = false,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      accessToken: accessToken,
      body: body,
      queryParameters: queryParameters,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    String? accessToken,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool handleUnauthorized,
  }) async {
    _throwIfOffline();

    final request = _buildRequest(
      method: method,
      path: path,
      accessToken: accessToken,
      body: body,
      queryParameters: queryParameters,
    );

    try {
      final response = await _sendRequest(request);
      final decodedBody = _decodeResponseBody(response.bodyBytes);

      if (response.statusCode == 401 && handleUnauthorized) {
        await onUnauthorized?.call();
        throw const ApiException(
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
          statusCode: 401,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            _extractErrorMessage(decodedBody) ??
            'فشل الاتصال بالخادم. رمز الحالة: ${response.statusCode}.';
        throw ApiException(message, statusCode: response.statusCode);
      }

      return decodedBody;
    } on TimeoutException {
      throw const ApiException(
        'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة أو عنوان الـ API ثم حاول مرة أخرى.',
      );
    } on http.ClientException {
      throw const ApiException(
        'تعذر الوصول إلى خادم Laravel. تحقق من عنوان الـ API والاتصال ثم حاول مرة أخرى.',
      );
    } on FormatException {
      throw const ApiException('استجابة الخادم ليست بصيغة JSON متوقعة.');
    }
  }

  void _throwIfOffline() {
    if (isOffline?.call() == true) {
      throw const ApiException(
        'لا يوجد اتصال بالإنترنت حاليًا. تحقق من الشبكة ثم حاول مرة أخرى.',
      );
    }
  }

  http.Request _buildRequest({
    required String method,
    required String path,
    String? accessToken,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';

    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    if (body != null) {
      request.body = jsonEncode(body);
    }

    return request;
  }

  Future<http.Response> _sendRequest(http.Request request) async {
    final streamedResponse = await _httpClient
        .send(request)
        .timeout(connectTimeout);
    return http.Response.fromStream(streamedResponse).timeout(receiveTimeout);
  }

  dynamic _decodeResponseBody(List<int> bodyBytes) {
    final rawBody = utf8.decode(bodyBytes, allowMalformed: true);
    if (rawBody.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } on FormatException {
      return rawBody;
    }
  }

  String? _extractErrorMessage(dynamic decodedBody) {
    if (decodedBody is String && decodedBody.trim().isNotEmpty) {
      return decodedBody.trim();
    }

    if (decodedBody is Map<String, dynamic>) {
      final errors = decodedBody['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first;
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }

      final message = decodedBody['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final error = decodedBody['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }

    return null;
  }

  String? _extractFileName(Map<String, String> headers) {
    final contentDisposition = headers['content-disposition'];
    if (contentDisposition == null || contentDisposition.isEmpty) {
      return null;
    }

    final utfMatch = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (utfMatch != null) {
      return Uri.decodeFull(utfMatch.group(1)!);
    }

    final plainMatch = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(contentDisposition);

    return plainMatch?.group(1);
  }
}

class ApiBinaryResponse {
  const ApiBinaryResponse({
    required this.bytes,
    this.fileName,
    this.contentType,
  });

  final Uint8List bytes;
  final String? fileName;
  final String? contentType;
}

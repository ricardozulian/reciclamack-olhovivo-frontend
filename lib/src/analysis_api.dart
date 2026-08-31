import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AnalysisApi {
  static const String _defaultApiBaseUrl = 'http://localhost:8000';
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  Future<Map<String, dynamic>> analyze(
    String filename,
    Uint8List bytes, {
    bool persist = true,
  }) async {
    var uri = _apiUri('/v1/analyze-image');
    if (!persist) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, 'persist': 'false'},
      );
    }
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _mediaTypeForFilename(filename),
        ),
      );
    final streamed = await request.send().timeout(const Duration(seconds: 25));
    final body = await streamed.stream.bytesToString();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (streamed.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'API error');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> analyzeWithRetry(
    String filename,
    Uint8List bytes,
  ) async {
    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await analyze(filename, bytes);
      } catch (error) {
        lastError = Exception(error.toString());
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        }
      }
    }
    throw lastError ?? Exception('Unknown analysis error');
  }

  MediaType _mediaTypeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  Uri _apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = _effectiveApiBaseUrl();
    if (base.isEmpty || base == '/') return Uri.parse(normalizedPath);
    return Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}$normalizedPath');
  }

  String _effectiveApiBaseUrl() {
    final configured = _apiBaseUrl.trim();
    if (!kIsWeb || configured != _defaultApiBaseUrl) return configured;
    if (Uri.base.scheme == 'https') return '/';
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return configured;
    }
    return 'http://$host:8000';
  }
}

List<Map<String, dynamic>> detectionsFrom(Map<String, dynamic>? result) {
  final value = result?['detections'];
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

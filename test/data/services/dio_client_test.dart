import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/services/dio_client.dart';

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._responses);

  final List<Future<ResponseBody> Function(RequestOptions)> _responses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = callCount;
    callCount++;
    if (index >= _responses.length) {
      throw StateError('No queued response left for call #$index');
    }
    return _responses[index](options);
  }

  @override
  void close({bool force = false}) {}
}

Future<ResponseBody> _jsonResponse(
  int statusCode,
  Map<String, dynamic> body,
) async {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio _buildTestDio(
  List<Future<ResponseBody> Function(RequestOptions)> responses, {
  List<int> retryableStatusCodes = const [503],
  int maxRetries = 2,
}) {
  final dio = Dio(BaseOptions());
  dio.httpClientAdapter = _QueueAdapter(responses);
  dio.interceptors.add(
    RetryInterceptor(
      dio,
      retryableStatusCodes: retryableStatusCodes,
      maxRetries: maxRetries,
    ),
  );
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test('does not retry a successful request', () async {
      final adapter = <Future<ResponseBody> Function(RequestOptions)>[
        (_) => _jsonResponse(200, {'ok': true}),
      ];
      final dio = _buildTestDio(adapter);

      final response = await dio.get('/test');

      expect(response.statusCode, 200);
      expect((dio.httpClientAdapter as _QueueAdapter).callCount, 1);
    });

    test('retries on 503 and succeeds on a later attempt', () async {
      final adapter = <Future<ResponseBody> Function(RequestOptions)>[
        (_) => _jsonResponse(503, {'error': 'unavailable'}),
        (_) => _jsonResponse(503, {'error': 'unavailable'}),
        (_) => _jsonResponse(200, {'ok': true}),
      ];
      final dio = _buildTestDio(adapter);

      final response = await dio.get('/test');

      expect(response.statusCode, 200);
      expect((dio.httpClientAdapter as _QueueAdapter).callCount, 3);
    });

    test('gives up after maxRetries on persistent 503', () async {
      final adapter = <Future<ResponseBody> Function(RequestOptions)>[
        (_) => _jsonResponse(503, {'error': 'unavailable'}),
        (_) => _jsonResponse(503, {'error': 'unavailable'}),
        (_) => _jsonResponse(503, {'error': 'unavailable'}),
      ];
      final dio = _buildTestDio(adapter);

      await expectLater(
        dio.get('/test'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            503,
          ),
        ),
      );

      // Initial attempt + 2 retries = 3 total calls, never a 4th.
      expect((dio.httpClientAdapter as _QueueAdapter).callCount, 3);
    });

    test('does not retry on 429', () async {
      final adapter = <Future<ResponseBody> Function(RequestOptions)>[
        (_) => _jsonResponse(429, {'error': 'rate limited'}),
      ];
      final dio = _buildTestDio(adapter, retryableStatusCodes: [503]);

      await expectLater(
        dio.get('/test'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            429,
          ),
        ),
      );

      expect((dio.httpClientAdapter as _QueueAdapter).callCount, 1);
    });

    test('retries on connection timeout', () async {
      final adapter = <Future<ResponseBody> Function(RequestOptions)>[
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
        (_) => _jsonResponse(200, {'ok': true}),
      ];
      final dio = _buildTestDio(adapter);

      final response = await dio.get('/test');

      expect(response.statusCode, 200);
      expect((dio.httpClientAdapter as _QueueAdapter).callCount, 2);
    });
  });
}

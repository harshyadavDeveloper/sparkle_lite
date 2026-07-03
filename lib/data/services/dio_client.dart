import 'package:dio/dio.dart';
import 'package:sparkle_lite/core/utils/logger.dart';

/// Centralized Dio instance with logging + retry built in.
/// Any service (Gemini, future APIs) should use DioClient.instance
/// instead of creating its own http/Dio client.
class DioClient {
  DioClient._();

  static final Dio instance =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 15),
          ),
        )
        ..interceptors.addAll([
          _LoggingInterceptor(),
          _RetryInterceptor(retryableStatusCodes: [503]),
        ]);
}

/// Logs every request/response/error using your existing Logger,
/// so behavior matches the rest of your app's logging style.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Logger.info('→ ${options.method} ${options.uri}');
    if (options.data != null) {
      final preview = options.data.toString();
      Logger.info(
        'Request body: ${preview.length > 300 ? '${preview.substring(0, 300)}...' : preview}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Logger.success('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Logger.error(
      '✗ ${err.response?.statusCode ?? err.type} ${err.requestOptions.uri}',
    );
    if (err.response?.data != null) {
      Logger.error('Error body: ${err.response?.data}');
    }
    handler.next(err);
  }
}

/// Retries requests on specific status codes (e.g. 503) or transient
/// network errors (timeout, connection issues), with exponential backoff.
/// Does NOT retry on 429 (rate limit) — retrying immediately on quota
/// exhaustion just wastes another call.
class _RetryInterceptor extends Interceptor {
  final List<int> retryableStatusCodes;
  final int maxRetries;

  _RetryInterceptor({required this.retryableStatusCodes, this.maxRetries = 2});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retryCount = (options.extra['retryCount'] as int?) ?? 0;

    final isRetryableStatus = retryableStatusCodes.contains(
      err.response?.statusCode,
    );
    final isRetryableNetworkError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if ((isRetryableStatus || isRetryableNetworkError) &&
        retryCount < maxRetries) {
      final delay = Duration(seconds: 2 * (retryCount + 1));
      Logger.info(
        '⟳ Retrying request (attempt ${retryCount + 1}/$maxRetries) after ${delay.inSeconds}s → ${options.uri}',
      );

      await Future.delayed(delay);

      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await DioClient.instance.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    handler.next(err);
  }
}

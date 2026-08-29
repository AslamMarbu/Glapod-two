import 'package:dio/dio.dart';
import 'package:Edmaster/constants/api_constants.dart';

import '../storage/local_storage_service.dart';
import '../utils/api_cache_service.dart';

class DioClient {
  static Dio? _dio;

  static const String baseUrl = ApiConstants.baseUrl;

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 1. AUTH INTERCEPTOR
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await LocalStorageService.getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            return handler.next(options);
          },
        ),
      );

      // 2. CACHE INTERCEPTOR
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final bool shouldSkipCache = _shouldSkipCache(options);

            if (options.method.toUpperCase() == 'GET' && !shouldSkipCache) {
              final String cacheKey = options.uri.toString();

              final cachedData = await ApiCacheService.getCachedData(cacheKey);

              if (cachedData != null) {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    data: cachedData,
                    statusCode: 200,
                    statusMessage: 'Loaded from cache',
                  ),
                );
              }
            }

            return handler.next(options);
          },

          onResponse: (response, handler) async {
            final RequestOptions options = response.requestOptions;

            final bool shouldSkipCache = _shouldSkipCache(options);

            if (options.method.toUpperCase() == 'GET' &&
                !shouldSkipCache &&
                response.statusCode == 200) {
              final String cacheKey = options.uri.toString();

              await ApiCacheService.cacheData(cacheKey, response.data);
            }

            return handler.next(response);
          },

          onError: (DioException error, handler) {
            return handler.next(error);
          },
        ),
      );

      // 3. LOGGING
      _dio!.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    return _dio!;
  }

  /// APIs listed here always fetch fresh data from server.
  static bool _shouldSkipCache(RequestOptions options) {
    final String path = options.path.toLowerCase();

    return path.contains('/api/study/get-subjects') ||
        path.contains('/api/game-zone/spelling-quiz') ||
        path.contains('/api/daily-quiz') ||
        path.contains('/api/gk-master') ||
        path.contains('/api/english-master/list') ||
        path.contains('/api/med-master/list');
  }

  /// Recreate the Dio instance when required.
  static void reset() {
    _dio?.close(force: true);
    _dio = null;
  }
}

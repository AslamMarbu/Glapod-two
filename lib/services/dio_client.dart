import 'package:dio/dio.dart';
import '../storage/local_storage_service.dart';
import '../utils/api_cache_service.dart';
import 'package:glapod/constants/api_constants.dart';

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
            return handler.next(options); // Continue request
          },
        ),
      );

      // 2. CACHE INTERCEPTOR (The 12-hour logic)
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.method == "GET" &&
                !options.path.contains('/api/study/get-subjects')) {
              // Use the path (e.g., /api/subjects) as the cache key
              final cachedData = await ApiCacheService.getCachedData(
                options.path,
              );
              if (cachedData != null) {
                // If cache exists, return it immediately and STOP the network call
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    data: cachedData,
                    statusCode: 200,
                  ),
                );
              }
            }
            return handler.next(options);
          },
          onResponse: (response, handler) async {
            // Save to cache only on successful GET requests
            if (response.requestOptions.method == "GET" &&
                response.statusCode == 200) {
              await ApiCacheService.cacheData(
                response.requestOptions.path,
                response.data,
              );
            }
            return handler.next(response);
          },
        ),
      );

      // 3. LOGGING (Crucial for debugging on your phone)
      _dio!.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    return _dio!;
  }
}

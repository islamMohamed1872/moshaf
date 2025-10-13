import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DioHelper {
  static late Dio dio;

  /// Initialize Dio with a base URL and allow both HTTP & HTTPS
  static void init() {
    dio = Dio(
      BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Allow self-signed certificates or insecure HTTP if needed (for development)
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.data != null) print('📦 DATA: ${options.data}');
          if (options.queryParameters.isNotEmpty) {
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR [${error.response?.statusCode}] ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.get(url, queryParameters: query);
  }

  /// POST request
  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    required dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.post(url, queryParameters: query, data: data);
  }

  /// PUT request
  static Future<Response> putData({
    required String url,
    Map<String, dynamic>? query,
    required dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.put(url, queryParameters: query, data: data);
  }

  /// DELETE request
  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    dio.options.headers.addAll(headers ?? {});
    return await dio.delete(url, queryParameters: query);
  }
}

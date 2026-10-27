import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xurmo/core/errors/app_exception.dart';

class NetworkModule {
  static final NetworkModule _instance = NetworkModule._internal();
  late Dio dio;

  factory NetworkModule() {
    return _instance;
  }

  NetworkModule._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://www.themealdb.com/api/json/v1/1/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// Performs a GET and converts any transport failure into an
  /// [AppException] carrying a message that is safe to show to the user.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw AppException.from(e);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}

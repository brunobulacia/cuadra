import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';
import '../storage/token_storage.dart';

/// Singleton de Dio preconfigurado:
/// - baseUrl apunta al backend NestJS
/// - AuthInterceptor inyecta el JWT en cada request
/// - Timeouts razonables
class ApiClient {
  ApiClient._();
  static ApiClient? _instance;

  late final Dio _dio;

  static ApiClient instance(TokenStorage tokenStorage) {
    _instance ??= ApiClient._().._init(tokenStorage);
    return _instance!;
  }

  void _init(TokenStorage tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(AuthInterceptor(tokenStorage));
  }

  Dio get dio => _dio;
}

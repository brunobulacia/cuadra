import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Interceptor que lee el JWT del [TokenStorage] y lo agrega como
/// `Authorization: Bearer <token>` en cada request saliente.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Podría lanzar un evento de sesión expirada (401) aquí si se necesita.
    handler.next(err);
  }
}

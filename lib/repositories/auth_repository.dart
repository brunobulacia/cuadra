import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_result.dart';
import '../models/profile.dart';

class AuthRepository {
  const AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Inicia sesión con email y contraseña.
  /// Guarda el token en [TokenStorage] y retorna [AuthResult].
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _tokenStorage.save(token);
    final profile = await _fetchMe();
    return AuthResult(accessToken: token, profile: profile);
  }

  /// Registra un nuevo usuario. El rol y negocio se configuran en el onboarding.
  Future<AuthResult> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {'nombre': nombre, 'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _tokenStorage.save(token);
    final profile = await _fetchMe();
    return AuthResult(accessToken: token, profile: profile);
  }

  /// Retorna el perfil del usuario autenticado leyendo el JWT almacenado.
  Future<Profile?> fetchCurrentProfile() async {
    final token = await _tokenStorage.read();
    if (token == null) return null;
    try {
      return await _fetchMe();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.delete();
        return null;
      }
      rethrow;
    }
  }

  /// Elimina el token guardado (logout local).
  Future<void> logout() => _tokenStorage.delete();

  Future<Profile> _fetchMe() async {
    final response = await _apiClient.dio.get(ApiEndpoints.me);
    return Profile.fromJson(response.data as Map<String, dynamic>);
  }
}

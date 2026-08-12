import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/business.dart';

class BusinessRepository {
  const BusinessRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Crea un negocio nuevo y vincula al usuario como jefe (onboarding boss).
  Future<Business> createBusiness(String nombre) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.businessesCreate,
      data: {'nombre': nombre},
    );
    return Business.fromJson(response.data as Map<String, dynamic>);
  }

  /// Une al usuario autenticado como empleado de un negocio (onboarding employee).
  Future<Business> joinBusiness(String codigo) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.businessesJoin,
      data: {'codigo': codigo.trim().toUpperCase()},
    );
    return Business.fromJson(response.data as Map<String, dynamic>);
  }

  /// Busca un negocio por su código (onboarding empleado).
  Future<Business?> findByCode(String code) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.businessesLookup,
      queryParameters: {'codigo': code.trim().toUpperCase()},
    );
    if (response.data == null) return null;
    return Business.fromJson(response.data as Map<String, dynamic>);
  }

  /// Retorna el negocio del usuario autenticado.
  Future<Business> fetchMyBusiness() async {
    final response = await _apiClient.dio.get(ApiEndpoints.businessesMe);
    return Business.fromJson(response.data as Map<String, dynamic>);
  }
}


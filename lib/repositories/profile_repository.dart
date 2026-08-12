import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/profile.dart';

class ProfileRepository {
  const ProfileRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Retorna los empleados del negocio del jefe autenticado.
  Future<List<Profile>> fetchEmployees(String businessId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.employees);
    return (response.data as List)
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Elimina un empleado del negocio.
  Future<void> removeEmployee(String employeeId) async {
    await _apiClient.dio.delete(ApiEndpoints.removeEmployee(employeeId));
  }
}

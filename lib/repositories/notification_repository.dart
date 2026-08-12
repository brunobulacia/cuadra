import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class NotificationRepository {
  const NotificationRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<void> saveNotification({
    required String businessId,
    required double monto,
    required String banco,
    required String textoCrudo,
  }) async {
    await _apiClient.dio.post(
      ApiEndpoints.notifications,
      data: {
        'businessId': businessId,
        'monto': monto,
        'banco': banco,
        'textoCrudo': textoCrudo,
      },
    );
  }

  /// Notificaciones recientes del negocio (fallback de polling del diálogo QR).
  Future<List<Map<String, dynamic>>> fetchRecent({int minutes = 10}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'minutes': minutes},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}


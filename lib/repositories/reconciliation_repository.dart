import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/reconciliation.dart';

class ReconciliationRepository {
  const ReconciliationRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Llama al endpoint `POST /reconciliation/run` y retorna el ID de la reconciliación.
  Future<String> runReconciliation({
    required DateTime fecha,
  }) async {
    final dateStr =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final response = await _apiClient.dio.post(
      ApiEndpoints.reconciliationRun,
      data: {'fecha': dateStr},
    );
    return response.data['id'] as String;
  }

  Future<double> fetchEfectivoTotal(String reconciliationId) async {
    final response = await _apiClient.dio.get('/reconciliation/$reconciliationId');
    // Prisma serializa Decimal como String ("30.00"); parsear robusto.
    return double.tryParse('${response.data['totalEfectivo']}') ?? 0;
  }

  Future<List<ReconciliationItem>> fetchItems(String reconciliationId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.reconciliationItems(reconciliationId),
    );
    return (response.data as List)
        .map((e) => ReconciliationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEfectivoFisico(
    String reconciliationId,
    double fisico,
  ) async {
    await _apiClient.dio.patch(
      '/reconciliation/$reconciliationId',
      data: {'efectivoFisico': fisico},
    );
  }
}


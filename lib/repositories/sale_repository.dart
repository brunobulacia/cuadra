import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/sale.dart';

class SaleRepository {
  const SaleRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Registra un carrito completo en una sola llamada (una Sale = un pago).
  Future<void> registerSale({
    required List<({String productId, int cantidad, double precio})> items,
    required String metodo,
  }) async {
    await _apiClient.dio.post(
      ApiEndpoints.sales,
      data: {
        'metodo': metodo,
        'items': items
            .map(
              (i) => {
                'productId': i.productId,
                'cantidad': i.cantidad,
                'precio': i.precio,
              },
            )
            .toList(),
      },
    );
  }

  /// Ventas del día de hoy del empleado autenticado.
  Future<List<Sale>> fetchTodaySales() async {
    final response = await _apiClient.dio.get(ApiEndpoints.salesMe);
    return (response.data as List)
        .map((e) => Sale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ventas de cualquier día (para el jefe). [date] en hora Bolivia.
  Future<List<Sale>> fetchSalesByDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _apiClient.dio.get(
      ApiEndpoints.sales,
      queryParameters: {'date': dateStr},
    );
    return (response.data as List)
        .map((e) => Sale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ventas de hoy de un empleado específico (endpoint /sales/me usa el JWT).
  Future<List<Sale>> fetchTodaySalesByEmployee(String employeeId) =>
      fetchTodaySales();
}


import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/product.dart';

class ProductRepository {
  const ProductRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Product>> fetchActiveProducts() async {
    final response = await _apiClient.dio.get(ApiEndpoints.products);
    return (response.data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createProduct({
    required String nombre,
    required double precio,
  }) async {
    await _apiClient.dio.post(
      ApiEndpoints.products,
      data: {'nombre': nombre, 'precio': precio},
    );
  }

  Future<void> toggleProduct(String id, {required bool activo}) async {
    await _apiClient.dio.patch(
      ApiEndpoints.product(id),
      data: {'activo': activo},
    );
  }

  Future<void> updateProduct(
    String id, {
    String? nombre,
    double? precio,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (precio != null) updates['precio'] = precio;
    if (updates.isEmpty) return;
    await _apiClient.dio.patch(ApiEndpoints.product(id), data: updates);
  }
}


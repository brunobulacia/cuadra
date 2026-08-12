/// Línea de un carrito (un producto + cantidad) dentro de una [Sale].
class SaleItem {
  final String? productId;
  final String? productNombre;
  final int cantidad;
  final double precio;
  final double subtotal;

  const SaleItem({
    this.productId,
    this.productNombre,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productId: json['productId'] as String?,
    productNombre:
        (json['product'] as Map<String, dynamic>?)?['nombre'] as String?,
    cantidad: json['cantidad'] as int,
    precio: double.parse('${json['precio']}'),
    subtotal: double.parse('${json['subtotal']}'),
  );
}

/// Una Sale = un pago/carrito completo. [monto] es el TOTAL pagado;
/// el detalle por producto está en [items].
class Sale {
  final String id;
  final String businessId;
  final String employeeId;
  final double monto;
  final String metodo;
  final DateTime createdAt;
  final String? employeeNombre; // populated when fetched with join
  final List<SaleItem> items;

  const Sale({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.monto,
    required this.metodo,
    required this.createdAt,
    this.employeeNombre,
    this.items = const [],
  });

  /// Resumen legible del carrito, ej. "2x Empanada" o "Café, Jugo".
  String get itemsSummary {
    if (items.isEmpty) return '';
    if (items.length == 1) {
      final i = items.first;
      final nombre = i.productNombre ?? 'Producto';
      return i.cantidad > 1 ? '${i.cantidad}x $nombre' : nombre;
    }
    return items.map((i) => i.productNombre ?? 'Producto').join(', ');
  }

  /// Construye una Sale desde la respuesta del backend NestJS (camelCase + Prisma includes).
  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] as String,
    businessId: json['businessId'] as String,
    employeeId: json['employeeId'] as String,
    monto: double.parse('${json['monto']}'),
    metodo: json['metodo'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    employeeNombre:
        (json['employee'] as Map<String, dynamic>?)?['nombre'] as String?,
    items: ((json['items'] as List?) ?? const [])
        .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Product {
  final String id;
  final String businessId;
  final String nombre;
  final double precio;
  final bool activo;

  const Product({
    required this.id,
    required this.businessId,
    required this.nombre,
    required this.precio,
    required this.activo,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        nombre: json['nombre'] as String,
        // Prisma serializa Decimal como String (ej. "15"); num como fallback.
        precio: double.parse('${json['precio']}'),
        activo: json['activo'] as bool,
      );
}

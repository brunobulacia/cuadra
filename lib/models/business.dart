class Business {
  final String id;
  final String nombre;
  final String codigo;

  const Business({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    codigo: json['codigo'] as String,
  );
}

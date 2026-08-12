class Profile {
  final String id;
  final String? businessId;
  final String nombre;
  final String rol;

  const Profile({
    required this.id,
    this.businessId,
    required this.nombre,
    required this.rol,
  });

  bool get isBoss => rol == 'boss';

  /// true si el usuario ya completó el onboarding (tiene negocio asignado).
  bool get hasCompletedOnboarding => businessId != null && businessId!.isNotEmpty;

  /// Construye un Profile desde la respuesta del backend NestJS.
  /// `/auth/me` retorna `{ userId, businessId, rol, nombre }`
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: (json['userId'] ?? json['id']) as String,
        businessId: json['businessId'] as String?,
        nombre: json['nombre'] as String,
        rol: (json['rol'] as String?) ?? 'employee',
      );
}

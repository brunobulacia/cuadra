class ReconciliationItem {
  final String id;
  final String estado;
  final double? ventaMonto;
  final DateTime? ventaHora;
  final double? notifMonto;
  final DateTime? notifHora;
  final String? banco;

  const ReconciliationItem({
    required this.id,
    required this.estado,
    this.ventaMonto,
    this.ventaHora,
    this.notifMonto,
    this.notifHora,
    this.banco,
  });

  /// Construye desde la respuesta NestJS: `sale.createdAt`, `notification.capturedAt`.
  factory ReconciliationItem.fromJson(Map<String, dynamic> json) {
    final sale = json['sale'] as Map<String, dynamic>?;
    final notif = json['notification'] as Map<String, dynamic>?;
    return ReconciliationItem(
      id: json['id'] as String,
      estado: json['estado'] as String,
      ventaMonto: sale != null ? double.parse('${sale['monto']}') : null,
      ventaHora: sale != null ? DateTime.parse(sale['createdAt'] as String) : null,
      notifMonto: notif != null ? double.parse('${notif['monto']}') : null,
      notifHora: notif != null ? DateTime.parse(notif['capturedAt'] as String) : null,
      banco: notif?['banco'] as String?,
    );
  }
}

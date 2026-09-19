import 'dart:convert';

import 'package:flutter/services.dart';

/// Pagos que el NotificationListenerService (BankNotificationService.kt)
/// captura en ESTE dispositivo: `{monto, banco, texto_crudo}`.
///
/// Instancia única compartida a propósito: el lado nativo guarda un solo
/// EventSink, así que cada `receiveBroadcastStream()` nuevo reemplaza al
/// anterior y al cancelarse deja a todos sin eventos. Un stream broadcast
/// compartido mantiene una sola suscripción nativa para todos los oyentes.
final Stream<Map<String, dynamic>> capturedPayments =
    const EventChannel('cuadra/notifications').receiveBroadcastStream().map(
      (raw) => jsonDecode(raw as String) as Map<String, dynamic>,
    );

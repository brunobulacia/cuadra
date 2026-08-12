import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/network/api_endpoints.dart';

// Eventos emitidos por el gateway NestJS
const _kNewSale = 'new_sale';
const _kNewNotification = 'new_notification';

/// Servicio de conexión a Socket.io.
/// Cada negocio tiene su sala `business:{businessId}`.
/// Expone streams de ventas y notificaciones nuevas.
class RealtimeService {
  RealtimeService._();
  static RealtimeService? _instance;
  static RealtimeService get instance => _instance ??= RealtimeService._();

  io.Socket? _socket;

  void connect({required String businessId, required String token}) {
    // Ya hay un socket vivo → nada que hacer.
    if (_socket?.connected == true) return;
    // Tirar cualquier socket viejo (ej. apuntando a un backend caído / otro puerto).
    _socket?.dispose();

    // La URL base sin el prefijo /api
    final wsUrl = ApiEndpoints.baseUrl.replaceFirst('/api', '');
    debugPrint('Socket: conectando a $wsUrl (business=$businessId)');

    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'businessId': businessId})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) => debugPrint('Socket: CONECTADO id=${_socket?.id}'))
      ..onConnectError((e) => debugPrint('Socket: connectError → $e'))
      ..onDisconnect((_) => debugPrint('Socket: desconectado'));

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  /// Escucha eventos `new_sale`. Llama [onSale] con el JSON de la venta.
  void onNewSale(void Function(Map<String, dynamic> data) onSale) {
    _socket?.on(_kNewSale, (data) {
      if (data is Map<String, dynamic>) onSale(data);
    });
  }

  /// Escucha eventos `new_notification`.
  void onNewNotification(
    void Function(Map<String, dynamic> data) onNotification,
  ) {
    _socket?.on(_kNewNotification, (data) {
      if (data is Map<String, dynamic>) onNotification(data);
    });
  }

  void offNewSale() => _socket?.off(_kNewSale);
  void offNewNotification() => _socket?.off(_kNewNotification);
}

// Provider para acceder al servicio desde Riverpod
final realtimeServiceProvider = Provider<RealtimeService>(
  (_) => RealtimeService.instance,
);

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../services/realtime_service.dart';
import 'repository_providers.dart';
import 'sale_provider.dart';

// ── MethodChannel / EventChannel constants ───────────────────────────────────

const _eventChannel = EventChannel('cuadra/notifications');
const _methodChannel = MethodChannel('cuadra/hub');

// ── State ────────────────────────────────────────────────────────────────────

class HubState {
  const HubState({
    this.hasPermission = false,
    this.allowedPackages = const <String>[],
    this.lastNotifMessage,
    this.lastConfigMessage,
    this.lastError,
  });

  final bool hasPermission;
  final List<String> allowedPackages;
  final String? lastNotifMessage;
  final String? lastConfigMessage;
  final String? lastError;

  HubState copyWith({
    bool? hasPermission,
    List<String>? allowedPackages,
    String? lastNotifMessage,
    String? lastConfigMessage,
    String? lastError,
  }) => HubState(
    hasPermission: hasPermission ?? this.hasPermission,
    allowedPackages: allowedPackages ?? this.allowedPackages,
    lastNotifMessage: lastNotifMessage ?? this.lastNotifMessage,
    lastConfigMessage: lastConfigMessage ?? this.lastConfigMessage,
    lastError: lastError ?? this.lastError,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class BossHubNotifier extends AutoDisposeNotifier<HubState> {
  StreamSubscription? _notifSub;

  @override
  HubState build() {
    ref.onDispose(() {
      _notifSub?.cancel();
      RealtimeService.instance.disconnect();
    });
    return const HubState();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Solo se llama cuando el onboarding está completo (businessId != null).
  Future<void> init(Profile profile) async {
    if (!Platform.isAndroid) return;
    final businessId = profile.businessId;
    if (businessId == null) return;
    await _checkPermission();
    await loadAllowedPackages();
    _listenNotifications(businessId);
    await _listenRealtimeSales(profile);
  }

  Future<void> checkPermission() => _checkPermission();

  Future<void> openPermissionSettings() async {
    await _methodChannel.invokeMethod('openPermissionSettings');
  }

  Future<void> loadAllowedPackages() async {
    if (!Platform.isAndroid) return;
    final packages = await _methodChannel
            .invokeListMethod<String>('getAllowedNotificationPackages') ??
        const <String>[];
    state = state.copyWith(allowedPackages: [...packages]..sort());
  }

  Future<void> saveAllowedPackages(List<String> packages) async {
    if (!Platform.isAndroid) return;
    final normalized = packages
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    await _methodChannel.invokeMethod('setAllowedNotificationPackages', {
      'packages': normalized,
    });
    state = state.copyWith(
      allowedPackages: normalized,
      lastConfigMessage: normalized.isEmpty
          ? 'Escuchando notificaciones de todas las apps'
          : 'Apps configuradas: ${normalized.length}',
      lastError: null,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _checkPermission() async {
    final granted =
        await _methodChannel.invokeMethod<bool>('isPermissionGranted') ?? false;
    state = state.copyWith(hasPermission: granted);
  }

  /// Escucha las notificaciones que captura el NotificationListenerService
  /// (ahora: la notif de pago de QRWallet) y las postea al backend.
  void _listenNotifications(String businessId) {
    _notifSub?.cancel();
    _notifSub = _eventChannel.receiveBroadcastStream().listen(
      (raw) async {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          await ref.read(notificationRepositoryProvider).saveNotification(
                businessId: businessId,
                monto: (data['monto'] as num).toDouble(),
                banco: data['banco'] as String,
                textoCrudo: data['texto_crudo'] as String,
              );
        } catch (e) {
          state = state.copyWith(lastError: 'Error al guardar notificación: $e');
        }
      },
      onError: (e) =>
          state = state.copyWith(lastError: 'EventChannel error: $e'),
    );
  }

  Future<void> _listenRealtimeSales(Profile profile) async {
    final businessId = profile.businessId;
    if (businessId == null) return;
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return;
    final realtime = ref.read(realtimeServiceProvider);
    realtime.connect(businessId: businessId, token: token);
    // Limpiar handlers previos por si init corre más de una vez.
    realtime.offNewSale();
    realtime.offNewNotification();
    realtime.onNewSale((_) => ref.invalidate(todaySalesProvider));
    realtime.onNewNotification((data) {
      final monto = double.tryParse('${data['monto']}') ?? 0;
      final banco = (data['banco'] as String?) ?? 'Pago';
      state = state.copyWith(
        lastNotifMessage:
            'Pago recibido: Bs ${monto.toStringAsFixed(2)} ($banco)',
        lastError: null,
      );
    });
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final bossHubProvider = NotifierProvider.autoDispose<BossHubNotifier, HubState>(
  BossHubNotifier.new,
);

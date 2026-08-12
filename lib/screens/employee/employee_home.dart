import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/product_visuals.dart';
import '../../core/widgets/motion.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';

class EmployeeHome extends ConsumerStatefulWidget {
  const EmployeeHome({super.key});

  @override
  ConsumerState<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends ConsumerState<EmployeeHome> {
  final Map<String, int> _cart = {};

  void _addToCart(Product p) {
    setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1);
  }

  void _removeFromCart(String productId) {
    setState(() {
      final qty = (_cart[productId] ?? 0) - 1;
      if (qty <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = qty;
      }
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  double _cartTotal(List<Product> products) {
    double total = 0;
    for (final entry in _cart.entries) {
      final p = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => products.first,
      );
      total += p.precio * entry.value;
    }
    return total;
  }

  void _showCheckout(BuildContext context, List<Product> products) {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CheckoutSheet(
        cart: Map.from(_cart),
        products: products,
        onSuccess: _clearCart,
        onQrSaleRegistered: (monto, items) =>
            _showQrWaiting(context, monto, items),
      ),
    );
  }

  void _showQrWaiting(
    BuildContext context,
    double monto,
    List<({Product product, int qty})> items,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QrPaymentWaitingDialog(
        monto: monto,
        items: items,
        timeout: const Duration(minutes: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final productsAsync = ref.watch(productsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${profile?.nombre ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.receipt),
            tooltip: 'Mis ventas de hoy',
            onPressed: () => context.go(AppRoutes.employeeSales),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sin productos en el catálogo'),
                ],
              ),
            );
          }
          return Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  final qty = _cart[p.id] ?? 0;
                  return FadeSlideIn(
                    index: i,
                    child: _ProductCard(
                      product: p,
                      quantity: qty,
                      onAdd: () => _addToCart(p),
                      onRemove: qty > 0 ? () => _removeFromCart(p.id) : null,
                    ),
                  );
                },
              ),
              // ── Carrito flotante ─────────────────────────────────────
              if (_cartCount > 0)
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: _CartButton(
                    count: _cartCount,
                    total: _cartTotal(products),
                    onTap: () => _showCheckout(context, products),
                    cs: cs,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    final visual = ProductVisuals.of(product.nombre);

    return PressScale(
      child: Card(
        color: inCart ? visual.container.withValues(alpha: 0.45) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: inCart ? visual.accent.withValues(alpha: 0.35) : CuadraTheme.outline,
            width: inCart ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono de categoría + nombre + precio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: visual.container,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(visual.icon, size: 21, color: visual.accent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${product.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: visual.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                // Controles
                if (inCart)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconBtn(
                        icon: LucideIcons.minus,
                        onTap: onRemove!,
                        filled: false,
                        accent: visual.accent,
                        container: visual.container,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          '$quantity',
                          key: ValueKey(quantity),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: visual.accent,
                          ),
                        ),
                      ),
                      _CircleIconBtn(
                        icon: LucideIcons.plus,
                        onTap: onAdd,
                        filled: true,
                        accent: visual.accent,
                        container: visual.container,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: visual.container,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(LucideIcons.plus, size: 16, color: visual.accent),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final Color accent;
  final Color container;

  const _CircleIconBtn({
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.accent,
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? accent : container,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : accent),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _CartButton({
    required this.count,
    required this.total,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ver carrito',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                'Bs ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checkout bottom sheet ─────────────────────────────────────────────────────

class _CheckoutSheet extends ConsumerStatefulWidget {
  final Map<String, int> cart;
  final List<Product> products;
  final VoidCallback onSuccess;
  final void Function(double monto, List<({Product product, int qty})> items)?
  onQrSaleRegistered;

  const _CheckoutSheet({
    required this.cart,
    required this.products,
    required this.onSuccess,
    this.onQrSaleRegistered,
  });

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  String _metodo = 'qr';
  bool _loading = false;

  double get _total {
    double t = 0;
    for (final entry in widget.cart.entries) {
      final p = widget.products.firstWhere((p) => p.id == entry.key);
      t += p.precio * entry.value;
    }
    return t;
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      if (_metodo == 'qr') {
        // Para QR: NO guardar aún. El diálogo registra la venta al confirmar.
        final items = widget.cart.entries.map((e) {
          final p = widget.products.firstWhere((p) => p.id == e.key);
          return (product: p, qty: e.value);
        }).toList();
        if (mounted) {
          widget.onSuccess();
          Navigator.pop(context);
          widget.onQrSaleRegistered?.call(_total, items);
        }
        return;
      }
      // Efectivo: guardar inmediatamente (un solo carrito = una sola venta)
      final repo = ref.read(saleRepositoryProvider);
      await repo.registerSale(
        metodo: _metodo,
        items: widget.cart.entries.map((e) {
          final p = widget.products.firstWhere((p) => p.id == e.key);
          return (productId: p.id, cantidad: e.value, precio: p.precio);
        }).toList(),
      );
      if (mounted) {
        ref.invalidate(myTodaySalesProvider);
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.cart.values.fold(0, (a, b) => a + b)} '
              'venta(s) registrada(s) · Bs ${_total.toStringAsFixed(2)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = widget.cart.entries
        .map(
          (e) => (
            product: widget.products.firstWhere((p) => p.id == e.key),
            qty: e.value,
          ),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirmar venta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          // ── Ítems ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: CuadraTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (e) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.value.qty}',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value.product.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                'Bs ${(e.value.product.precio * e.value.qty).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (e.key < items.length - 1)
                          const Divider(height: 1, indent: 56, endIndent: 16),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          // ── Total ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                'Bs ${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: cs.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Método de pago ──────────────────────────────────────────────
          Text(
            'Método de pago',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'qr',
                label: Text('QR'),
                icon: Icon(LucideIcons.qrCode),
              ),
              ButtonSegment(
                value: 'efectivo',
                label: Text('Efectivo'),
                icon: Icon(LucideIcons.banknote),
              ),
            ],
            selected: {_metodo},
            onSelectionChanged: (v) => setState(() => _metodo = v.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _register,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}

// ── QR Payment Waiting Dialog ─────────────────────────────────────────────────

class _QrPaymentWaitingDialog extends ConsumerStatefulWidget {
  final double monto;
  final List<({Product product, int qty})> items;
  final Duration timeout;

  const _QrPaymentWaitingDialog({
    required this.monto,
    required this.items,
    this.timeout = const Duration(minutes: 3),
  });

  @override
  ConsumerState<_QrPaymentWaitingDialog> createState() =>
      _QrPaymentWaitingDialogState();
}

class _QrPaymentWaitingDialogState
    extends ConsumerState<_QrPaymentWaitingDialog> {
  bool _confirmed = false;
  String? _pagador;
  Timer? _timeout;
  Timer? _poll;
  bool _timedOut = false;

  /// capturedAt (hora del SERVIDOR) de la notif más reciente al abrir el
  /// diálogo. El polling solo acepta notifs posteriores a esto — así no
  /// confirma con pagos viejos y es inmune al desfase de reloj del emulador.
  DateTime? _baseline;

  @override
  void initState() {
    super.initState();
    _startListening();
    _startPolling();
    _timeout = Timer(widget.timeout, () {
      if (mounted && !_confirmed) setState(() => _timedOut = true);
    });
  }

  Future<void> _startListening() async {
    final realtime = ref.read(realtimeServiceProvider);
    // El empleado no conecta el socket en ningún otro lado (a diferencia del
    // jefe, que lo hace en BossHubNotifier). Lo aseguramos acá antes de
    // escuchar. connect() es idempotente: si ya está conectado, no hace nada.
    final businessId = ref.read(profileProvider)?.businessId;
    final token = await ref.read(tokenStorageProvider).read();
    if (businessId != null && token != null) {
      realtime.connect(businessId: businessId, token: token);
    }
    if (!mounted) return;
    debugPrint('QR Realtime: subscribing | monto=${widget.monto}');
    // Limpiar cualquier listener viejo (de un diálogo anterior) antes de registrar.
    realtime.offNewNotification();
    realtime.onNewNotification((data) {
      // Prisma serializa Decimal como String ("35"); parsear robusto.
      final notifMonto = double.tryParse('${data['monto']}') ?? 0;
      debugPrint(
        'QR Realtime: notifMonto=$notifMonto | esperado=${widget.monto} | diff=${(notifMonto - widget.monto).abs()}',
      );
      if ((notifMonto - widget.monto).abs() <= 0.50) {
        _confirm((data['textoCrudo'] as String?) ?? '');
      }
    });
  }

  /// Fallback de polling: si el WebSocket parpadea justo cuando llega el pago,
  /// el evento se pierde para siempre (socket.io no re-entrega). Consultando el
  /// backend cada 3s el cierre llega igual, como mucho unos segundos después.
  Future<void> _startPolling() async {
    try {
      final recent = await ref
          .read(notificationRepositoryProvider)
          .fetchRecent(minutes: 60);
      _baseline = recent.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse('${recent.first['capturedAt']}');
    } catch (_) {
      // Sin baseline: el matcher exige notifs muy recientes (ver _matches).
    }
    if (!mounted) return;
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkRecent());
  }

  Future<void> _checkRecent() async {
    if (_confirmed || _timedOut || !mounted) return;
    try {
      final recent = await ref
          .read(notificationRepositoryProvider)
          .fetchRecent(minutes: 5);
      for (final n in recent) {
        if (_matches(n)) {
          debugPrint('QR polling: match → ${n['monto']} (${n['banco']})');
          _confirm((n['textoCrudo'] as String?) ?? '');
          return;
        }
      }
    } catch (_) {
      // Backend inaccesible: se reintenta en el próximo tick.
    }
  }

  bool _matches(Map<String, dynamic> n) {
    final monto = double.tryParse('${n['monto']}') ?? 0;
    if ((monto - widget.monto).abs() > 0.50) return false;
    final at = DateTime.tryParse('${n['capturedAt']}');
    if (at == null) return false;
    if (_baseline != null) return at.isAfter(_baseline!);
    // Sin baseline (falló el fetch inicial): aceptar solo notifs muy nuevas.
    return DateTime.now().toUtc().difference(at.toUtc()).abs() <
        const Duration(minutes: 2);
  }

  /// Punto único de confirmación (lo usan el WS y el polling; corre una vez).
  void _confirm(String texto) {
    if (_confirmed || !mounted) return;
    _poll?.cancel();
    _timeout?.cancel();
    setState(() {
      _confirmed = true;
      _pagador = _extractPagador(texto);
    });
    _registerSales();
  }

  Future<void> _registerSales() async {
    final repo = ref.read(saleRepositoryProvider);
    // Un solo carrito pagado por QR = una sola venta (Sale.id agrupa los ítems).
    await repo.registerSale(
      metodo: 'qr',
      items: widget.items
          .map(
            (item) => (
              productId: item.product.id,
              cantidad: item.qty,
              precio: item.product.precio,
            ),
          )
          .toList(),
    );
    ref.invalidate(myTodaySalesProvider);
  }

  /// Extracts payer name from patterns like "de NOMBRE APELLIDO"
  String? _extractPagador(String texto) {
    final match = RegExp(
      r'\bde\s+([A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑA-Za-záéíóúñ\s]{2,40})',
      caseSensitive: false,
    ).firstMatch(texto);
    return match?.group(1)?.trim();
  }

  @override
  void dispose() {
    ref.read(realtimeServiceProvider).offNewNotification();
    _timeout?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_confirmed) {
      return AlertDialog(
        icon: const Icon(LucideIcons.circleCheck, color: CuadraTheme.success, size: 56),
        title: const Text('¡Pago confirmado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bs ${widget.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            if (_pagador != null) ...[
              const SizedBox(height: 8),
              Text(
                'de $_pagador',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ],
      );
    }

    if (_timedOut) {
      return AlertDialog(
        icon: Icon(LucideIcons.timer, color: cs.error, size: 48),
        title: const Text('Tiempo agotado'),
        content: const Text(
          'No se recibió confirmación del pago. Verificá con el cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Escanear para pagar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bs ${widget.monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/qr.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Esperando confirmación...',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

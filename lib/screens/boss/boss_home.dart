import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bolivia_time.dart';
import '../../models/sale.dart';
import '../../providers/providers.dart';

class BossHome extends ConsumerStatefulWidget {
  const BossHome({super.key});

  @override
  ConsumerState<BossHome> createState() => _BossHomeState();
}

class _BossHomeState extends ConsumerState<BossHome>
    with WidgetsBindingObserver {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(authNotifierProvider, (_, next) {
      next.whenData((authState) {
        final profile = authState.profile;
        if (profile != null) {
          ref.read(bossHubProvider.notifier).init(profile);
        }
      });
    }, fireImmediately: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      ref.read(bossHubProvider.notifier).checkPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final salesAsync = _selectedDate == null
        ? ref.watch(todaySalesProvider)
        : ref.watch(salesByDateProvider(_selectedDate!));
    final hub = ref.watch(bossHubProvider);
    final cs = Theme.of(context).colorScheme;
    final isToday = _selectedDate == null;
    final boliviaToday = BoliviaTime.now();

    ref.listen(bossHubProvider, (prev, next) {
      if (next.lastNotifMessage != null &&
          next.lastNotifMessage != prev?.lastNotifMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastNotifMessage!),
            backgroundColor: CuadraTheme.onSuccessContainer,
          ),
        );
      }
      if (next.lastError != null && next.lastError != prev?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastError!), backgroundColor: cs.error),
        );
      }
      if (next.lastConfigMessage != null &&
          next.lastConfigMessage != prev?.lastConfigMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.lastConfigMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${profile?.nombre ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.users),
            tooltip: 'Gestionar empleados',
            onPressed: () => context.push(AppRoutes.employees),
          ),
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(LucideIcons.slidersHorizontal),
              tooltip: 'Configurar apps bancarias',
              onPressed: () => _showNotificationAppsDialog(hub.allowedPackages),
            ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'Código del negocio',
            onPressed: () {
              final business = ref.read(businessProvider).valueOrNull;
              if (business == null) return;
              _showBusinessCode(context, cs, business.codigo);
            },
          ),
          IconButton(
            icon: Icon(
              isToday ? LucideIcons.calendar : LucideIcons.calendar,
              color: isToday ? null : cs.primary,
            ),
            tooltip: 'Cambiar fecha',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? boliviaToday,
                firstDate: DateTime(2025),
                lastDate: boliviaToday,
              );
              if (picked != null) {
                final isPickedToday =
                    picked.year == boliviaToday.year &&
                    picked.month == boliviaToday.month &&
                    picked.day == boliviaToday.day;
                setState(() => _selectedDate = isPickedToday ? null : picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          final totalQr = sales
              .where((s) => s.metodo == 'qr')
              .fold<double>(0, (sum, s) => sum + s.monto);
          final totalEfectivo = sales
              .where((s) => s.metodo == 'efectivo')
              .fold<double>(0, (sum, s) => sum + s.monto);
          final totalGeneral = totalQr + totalEfectivo;

          return RefreshIndicator(
            onRefresh: () async {
              if (isToday) {
                ref.invalidate(todaySalesProvider);
              } else {
                ref.invalidate(salesByDateProvider(_selectedDate!));
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (Platform.isAndroid && !hub.hasPermission && isToday)
                  _PermissionBanner(
                    onTap: () => ref
                        .read(bossHubProvider.notifier)
                        .openPermissionSettings(),
                  ),
                // ── Encabezado de fecha ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Resumen de hoy' : 'Resumen del día',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isToday
                              ? _formatDate(boliviaToday)
                              : _formatDate(_selectedDate!),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (!isToday)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedDate = null),
                        icon: const Icon(LucideIcons.calendarCheck, size: 16),
                        label: const Text('Ir a hoy'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Tarjeta total general ───────────────────────────────
                _TotalCard(total: totalGeneral, salesCount: sales.length),
                const SizedBox(height: 12),
                // ── QR + Efectivo ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MethodCard(
                        label: 'QR',
                        amount: totalQr,
                        icon: LucideIcons.qrCode,
                        color: cs.primary,
                        containerColor: cs.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodCard(
                        label: 'Efectivo',
                        amount: totalEfectivo,
                        icon: LucideIcons.banknote,
                        color: cs.secondary,
                        containerColor: cs.secondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Acciones ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.bookOpen,
                        label: 'Catálogo',
                        onTap: () => context.go(AppRoutes.catalog),
                        primary: false,
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.scale,
                        label: 'Arqueo',
                        onTap: () => context.go(AppRoutes.reconciliation),
                        primary: true,
                        cs: cs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Lista de ventas ─────────────────────────────────────
                if (sales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.receipt,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isToday
                              ? 'Sin ventas registradas hoy'
                              : 'Sin ventas ese día',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ventas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sales.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: sales
                          .asMap()
                          .entries
                          .map(
                            (e) => Column(
                              children: [
                                _BossSaleTile(sale: e.value),
                                if (e.key < sales.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 72,
                                    endIndent: 16,
                                  ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNotificationAppsDialog(List<String> currentPackages) async {
    final controller = TextEditingController(text: currentPackages.join('\n'));
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apps bancarias a escuchar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa package names, uno por línea (o separados por coma).',
              ),
              const SizedBox(height: 8),
              const Text(
                'Ejemplo: com.bancosol.app',
                style: TextStyle(color: CuadraTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'com.bancosol.app\ncom.tigomoney.app',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si lo dejas vacío, se leerán notificaciones de todas las apps.',
                style: TextStyle(color: CuadraTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final packages = controller.text
                  .split(RegExp(r'[\n,]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toSet()
                  .toList();
              await ref
                  .read(bossHubProvider.notifier)
                  .saveAllowedPackages(packages);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // Defer dispose until after the closing animation completes
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
  }

  String _formatDate(DateTime d) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  void _showBusinessCode(BuildContext context, ColorScheme cs, String codigo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Código del negocio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartí este código con tus empleados para que se unan:',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                codigo,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double total;
  final int salesCount;

  const _TotalCard({required this.total, required this.salesCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total recaudado',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bs ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$salesCount ventas',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color containerColor;

  const _MethodCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bs ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final ColorScheme cs;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(0, 48),
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(0, 48),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          LucideIcons.bellOff,
          color: cs.onErrorContainer,
        ),
        title: Text(
          'Permiso de notificaciones requerido',
          style: TextStyle(
            color: cs.onErrorContainer,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Toca para habilitar la captura automática',
          style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 14,
          color: cs.onErrorContainer,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _BossSaleTile extends StatelessWidget {
  final Sale sale;
  const _BossSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isQr = sale.metodo == 'qr';
    final cs = Theme.of(context).colorScheme;
    final hora = BoliviaTime.formatTime(sale.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isQr ? cs.primaryContainer : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isQr ? LucideIcons.qrCode : LucideIcons.banknote,
          size: 18,
          color: isQr ? cs.primary : cs.secondary,
        ),
      ),
      title: Text(
        'Bs ${sale.monto.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sale.itemsSummary.isNotEmpty)
            Text(
              sale.itemsSummary,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          Text(
            sale.employeeNombre ?? 'Empleado',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      isThreeLine: sale.itemsSummary.isNotEmpty,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            hora,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isQr ? cs.primaryContainer : cs.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isQr ? 'QR' : 'Efectivo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isQr ? cs.primary : cs.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

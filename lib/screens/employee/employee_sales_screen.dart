import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/bolivia_time.dart';
import '../../models/sale.dart';
import '../../providers/providers.dart';

class EmployeeSalesScreen extends ConsumerWidget {
  const EmployeeSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(myTodaySalesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ventas de hoy'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(myTodaySalesProvider),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.receipt,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Todavía no registraste ventas hoy',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus ventas del día aparecerán aquí',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final totalQr = sales
              .where((s) => s.metodo == 'qr')
              .fold<double>(0, (sum, s) => sum + s.monto);
          final totalEfectivo = sales
              .where((s) => s.metodo == 'efectivo')
              .fold<double>(0, (sum, s) => sum + s.monto);

          return Column(
            children: [
              // ── Resumen ─────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'QR',
                        value: 'Bs ${totalQr.toStringAsFixed(2)}',
                        icon: LucideIcons.qrCode,
                        color: cs.primary,
                        containerColor: cs.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Efectivo',
                        value: 'Bs ${totalEfectivo.toStringAsFixed(2)}',
                        icon: LucideIcons.banknote,
                        color: cs.secondary,
                        containerColor: cs.secondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Ventas',
                        value: '${sales.length}',
                        icon: LucideIcons.receipt,
                        color: cs.tertiary,
                        containerColor: cs.tertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ── Lista ────────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: sales.length,
                  itemBuilder: (_, i) {
                    final isLast = i == sales.length - 1;
                    return Column(
                      children: [
                        _SaleTile(sale: sales[i]),
                        if (!isLast)
                          const Divider(height: 1, indent: 68, endIndent: 0),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color containerColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isQr = sale.metodo == 'qr';
    final cs = Theme.of(context).colorScheme;
    final hora = BoliviaTime.formatTime(sale.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
        sale.itemsSummary.isNotEmpty
            ? sale.itemsSummary
            : 'Bs ${sale.monto.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        sale.itemsSummary.isNotEmpty
            ? 'Bs ${sale.monto.toStringAsFixed(2)} · ${isQr ? 'QR' : 'Efectivo'}'
            : (isQr ? 'QR' : 'Efectivo'),
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Text(
        hora,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

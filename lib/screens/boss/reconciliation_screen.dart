import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bolivia_time.dart';
import '../../models/reconciliation.dart';
import '../../providers/providers.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  bool _running = false;
  String? _reconId;
  List<ReconciliationItem> _items = [];
  String? _error;
  double? _totalEfectivo;
  double? _efectivoFisico;
  final _efectivoCtrl = TextEditingController();

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _items = [];
      _reconId = null;
      _totalEfectivo = null;
      _efectivoFisico = null;
    });
    try {
      final profile = ref.read(profileProvider);
      if (profile == null) return;
      final repo = ref.read(reconciliationRepositoryProvider);
      final id = await repo.runReconciliation(
        fecha: BoliviaTime.now(),
      );
      final items = await repo.fetchItems(id);
      final totalEfectivo = await repo.fetchEfectivoTotal(id);
      if (mounted) {
        setState(() {
          _reconId = id;
          _items = items;
          _totalEfectivo = totalEfectivo;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _guardarEfectivo() async {
    final fisico = double.tryParse(_efectivoCtrl.text.replaceAll(',', '.'));
    if (fisico == null || _reconId == null) return;
    await ref
        .read(reconciliationRepositoryProvider)
        .saveEfectivoFisico(_reconId!, fisico);
    if (mounted) setState(() => _efectivoFisico = fisico);
  }

  // Una Sale ya es el carrito/pago completo (monto = total), así que cada
  // ReconciliationItem representa un pago entero — no hace falta agrupar.
  List<ReconciliationItem> _byEstado(String estado) =>
      _items.where((i) => i.estado == estado).toList();

  @override
  void dispose() {
    _efectivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _byEstado('match');
    final sinRegistro = _byEstado('notif_sin_registro');
    final sinNotif = _byEstado('registro_sin_notif');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Arqueo del día')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _running ? null : _run,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.play),
              label: Text(_running ? 'Procesando...' : 'Correr arqueo de hoy'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.triangleAlert, color: cs.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_reconId != null) ...[
              const SizedBox(height: 16),
              // ── Cuadre de efectivo ──────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.banknote,
                              size: 16,
                              color: cs.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Efectivo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _EfectivoStat(
                              label: 'Ventas registradas',
                              value: _totalEfectivo ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EfectivoStat(
                              label: 'Conteo físico',
                              value: _efectivoFisico,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EfectivoStat(
                              label: 'Diferencia',
                              value: _efectivoFisico != null
                                  ? (_efectivoFisico! - (_totalEfectivo ?? 0))
                                  : null,
                              isBalance: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _efectivoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Conté Bs...',
                                prefixText: 'Bs ',
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _guardarEfectivo(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _guardarEfectivo,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _BucketSection(
                      icon: LucideIcons.circleCheck,
                      color: CuadraTheme.success,
                      containerColor: CuadraTheme.successContainer,
                      title: 'Ventas cuadradas',
                      count: matches.length,
                      items: matches,
                    ),
                    const SizedBox(height: 10),
                    _BucketSection(
                      icon: LucideIcons.triangleAlert,
                      color: CuadraTheme.warning,
                      containerColor: CuadraTheme.warningContainer,
                      title: 'Plata sin registro',
                      subtitle: 'Pago QR sin venta anotada',
                      count: sinRegistro.length,
                      items: sinRegistro,
                    ),
                    const SizedBox(height: 10),
                    _BucketSection(
                      icon: LucideIcons.circleHelp,
                      color: cs.error,
                      containerColor: CuadraTheme.errorContainer,
                      title: 'Registro sin pago QR',
                      subtitle: '¿Efectivo? ¿Error? ¿Venta inventada?',
                      count: sinNotif.length,
                      items: sinNotif,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EfectivoStat extends StatelessWidget {
  final String label;
  final double? value;
  final bool isBalance;

  const _EfectivoStat({
    required this.label,
    this.value,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (isBalance && value != null) {
      color = value! >= 0
          ? CuadraTheme.success
          : Theme.of(context).colorScheme.error;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value != null ? 'Bs ${value!.toStringAsFixed(2)}' : '—',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BucketSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color containerColor;
  final String title;
  final String? subtitle;
  final int count;

  final List<ReconciliationItem> items;

  const _BucketSection({
    required this.icon,
    required this.color,
    required this.containerColor,
    required this.title,
    this.subtitle,
    required this.count,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          '$title ($count)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        children: items.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Ninguno',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]
            : items.map((item) => _ItemTile(item: item)).toList(),
      ),
    );
  }
}

/// Sale.monto ya es el total del carrito (una Sale = un pago), así que cada
/// item representa una venta completa — no hace falta agrupar ítems.
class _ItemTile extends StatelessWidget {
  final ReconciliationItem item;

  const _ItemTile({required this.item});

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    final bolivia = dt.toUtc().subtract(const Duration(hours: 4));
    return '${bolivia.hour.toString().padLeft(2, '0')}:${bolivia.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monto = item.ventaMonto ?? item.notifMonto;
    final hora = item.ventaHora ?? item.notifHora;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        'Bs ${monto?.toStringAsFixed(2) ?? '—'}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        item.estado == 'match'
            ? 'Venta ${_fmt(item.ventaHora)} · Notif ${_fmt(item.notifHora)} · ${item.banco ?? ''}'
            : item.estado == 'notif_sin_registro'
            ? '${item.banco ?? 'Banco'} · ${_fmt(hora)}'
            : 'Registrado ${_fmt(hora)}',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }
}

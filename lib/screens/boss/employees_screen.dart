import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile.dart';
import '../../providers/providers.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay empleados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compartí el código del negocio para que se unan.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(employeesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final employee = employees[index];
                return _EmployeeTile(employee: employee);
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Tile individual ───────────────────────────────────────────────────────────

class _EmployeeTile extends ConsumerWidget {
  const _EmployeeTile({required this.employee});

  final Profile employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          employee.nombre.isNotEmpty ? employee.nombre[0].toUpperCase() : '?',
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(employee.nombre),
      trailing: IconButton(
        icon: Icon(LucideIcons.userMinus, color: cs.error),
        tooltip: 'Dar de baja',
        onPressed: () => _confirmRemove(context, ref, employee),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, Profile employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar de baja empleado'),
        content: Text(
          '¿Querés dar de baja a ${employee.nombre}?\n\n'
          'El empleado perderá acceso al negocio. '
          'Puede volver a unirse con el código si querés reincorporarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(profileRepositoryProvider)
                    .removeEmployee(employee.id);
                ref.invalidate(employeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${employee.nombre} fue dado de baja.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
  }
}

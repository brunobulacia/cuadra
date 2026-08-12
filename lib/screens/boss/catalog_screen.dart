import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/product_visuals.dart';
import '../../core/widgets/motion.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final profileAsync = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      floatingActionButton: FloatingActionButton(
        onPressed: profileAsync == null
            ? null
            : () => _showAddDialog(context, ref),
        child: const Icon(LucideIcons.plus),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) => products.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 56,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text('Sin productos'),
                    const SizedBox(height: 6),
                    Text(
                      'Tocá + para agregar uno',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FadeSlideIn(
                  index: i,
                  child: _ProductTile(
                    product: products[i],
                    onTap: () => _showEditDialog(
                      context,
                      ref,
                      products[i].id,
                      currentNombre: products[i].nombre,
                      currentPrecio: products[i].precio,
                    ),
                    onToggle: (v) async {
                      await ref
                          .read(productRepositoryProvider)
                          .toggleProduct(products[i].id, activo: v);
                      ref.invalidate(productsProvider);
                    },
                  ),
                ),
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _ProductDialog(
        title: 'Nuevo producto',
        nombreCtrl: nombreCtrl,
        precioCtrl: precioCtrl,
        onConfirm: () async {
          final precio = double.tryParse(
            precioCtrl.text.replaceAll(',', '.'),
          );
          if (nombreCtrl.text.isEmpty || precio == null) return;
          Navigator.pop(ctx);
          await ref.read(productRepositoryProvider).createProduct(
                nombre: nombreCtrl.text.trim(),
                precio: precio,
              );
          ref.invalidate(productsProvider);
        },
        confirmLabel: 'Agregar',
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String productId, {
    required String currentNombre,
    required double currentPrecio,
  }) {
    final nombreCtrl = TextEditingController(text: currentNombre);
    final precioCtrl = TextEditingController(
      text: currentPrecio.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => _ProductDialog(
        title: 'Editar producto',
        nombreCtrl: nombreCtrl,
        precioCtrl: precioCtrl,
        onConfirm: () async {
          final precio = double.tryParse(
            precioCtrl.text.replaceAll(',', '.'),
          );
          if (nombreCtrl.text.isEmpty || precio == null) return;
          Navigator.pop(ctx);
          await ref.read(productRepositoryProvider).updateProduct(
                productId,
                nombre: nombreCtrl.text.trim(),
                precio: precio,
              );
          ref.invalidate(productsProvider);
        },
        confirmLabel: 'Guardar',
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visual = ProductVisuals.of(product.nombre);
    return PressScale(
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: product.activo ? visual.container : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              visual.icon,
              size: 20,
              color: product.activo ? visual.accent : cs.onSurfaceVariant,
            ),
          ),
          title: Text(
            product.nombre,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: product.activo ? null : cs.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            'Bs ${product.precio.toStringAsFixed(2)}',
            style: TextStyle(
              color: product.activo ? visual.accent : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Switch(value: product.activo, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDialog extends StatelessWidget {
  final String title;
  final TextEditingController nombreCtrl;
  final TextEditingController precioCtrl;
  final VoidCallback onConfirm;
  final String confirmLabel;

  const _ProductDialog({
    required this.title,
    required this.nombreCtrl,
    required this.precioCtrl,
    required this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: precioCtrl,
            decoration: const InputDecoration(
              labelText: 'Precio (Bs)',
              prefixText: 'Bs ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onConfirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() =>
      _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _businessCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _businessCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final nombre = _businessCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresá el nombre del negocio');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Crea el negocio. El backend vincula al usuario autenticado como jefe.
      await ref.read(businessRepositoryProvider).createBusiness(nombre);

      // Recargar el perfil para que el router detecte el businessId asignado
      ref.invalidate(authNotifierProvider);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear negocio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(LucideIcons.store, size: 56, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'Nombre de tu negocio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tus empleados verán este nombre cuando se unan',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _businessCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del negocio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.store),
                  hintText: 'Ej: Tienda Don Carlos',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _create(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear negocio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

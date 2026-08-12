import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class JoinBusinessScreen extends ConsumerStatefulWidget {
  const JoinBusinessScreen({super.key});

  @override
  ConsumerState<JoinBusinessScreen> createState() => _JoinBusinessScreenState();
}

class _JoinBusinessScreenState extends ConsumerState<JoinBusinessScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresá el código del negocio');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Une al usuario autenticado como empleado del negocio con ese código.
      // El backend retorna error si el código no existe.
      await ref.read(businessRepositoryProvider).joinBusiness(code);

      // Recargar el perfil para que el router detecte el businessId asignado
      ref.invalidate(authNotifierProvider);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('404')
            ? 'Código incorrecto. Pedíselo a tu dueño.'
            : 'Error: $e';
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse al negocio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(LucideIcons.userPlus, size: 56, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'Ingresá el código del negocio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu dueño o encargado tiene este código. Pedíselo para unirte.',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código del negocio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.key),
                  hintText: 'Ej: TIENDA4821',
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _join(),
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
                onPressed: _loading ? null : _join,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unirse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

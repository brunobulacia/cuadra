import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

/// Perfil del usuario autenticado derivado del estado JWT.
/// Retorna null si el usuario no está autenticado.
final profileProvider = Provider<Profile?>((ref) {
  return ref.watch(currentProfileProvider);
});


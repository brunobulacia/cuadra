import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import 'repository_providers.dart';
import 'profile_provider.dart';

/// El negocio del usuario autenticado. Usado por el jefe para ver el código.
final businessProvider = FutureProvider<Business?>((ref) async {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;
  return ref.read(businessRepositoryProvider).fetchMyBusiness();
});

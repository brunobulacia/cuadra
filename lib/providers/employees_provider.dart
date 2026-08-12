import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import 'profile_provider.dart';
import 'repository_providers.dart';

/// Lista de empleados del negocio del jefe actualmente logueado.
final employeesProvider = FutureProvider<List<Profile>>((ref) async {
  final profile = ref.watch(profileProvider);
  if (profile == null) return [];
  final businessId = profile.businessId;
  if (businessId == null) return [];
  return ref
      .watch(profileRepositoryProvider)
      .fetchEmployees(businessId);
});

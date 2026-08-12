import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/bolivia_time.dart';
import '../models/sale.dart';
import 'repository_providers.dart';
import 'profile_provider.dart';

/// Today's sales for the whole business (used by boss). Invalidate to refresh.
/// Pega a GET /sales?date=hoy (todo el negocio), NO /sales/me (solo propias).
final todaySalesProvider = FutureProvider<List<Sale>>((ref) {
  return ref.watch(saleRepositoryProvider).fetchSalesByDate(BoliviaTime.now());
});

/// Sales for any given date (Bolivia local). Used by boss history picker.
final salesByDateProvider = FutureProvider.family<List<Sale>, DateTime>((
  ref,
  date,
) {
  return ref.read(saleRepositoryProvider).fetchSalesByDate(date);
});

/// Today's sales for the currently logged-in employee only.
final myTodaySalesProvider = FutureProvider<List<Sale>>((ref) async {
  final profile = ref.watch(profileProvider);
  if (profile == null) return [];
  return ref
      .watch(saleRepositoryProvider)
      .fetchTodaySalesByEmployee(profile.id);
});

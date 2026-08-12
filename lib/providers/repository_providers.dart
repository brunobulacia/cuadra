import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/reconciliation_repository.dart';
import '../repositories/business_repository.dart';

// ── Infraestructura ──────────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => const TokenStorage(FlutterSecureStorage()),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final ts = ref.watch(tokenStorageProvider);
  return ApiClient.instance(ts);
});

// ── Repositories ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(ref.watch(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);

final reconciliationRepositoryProvider = Provider<ReconciliationRepository>(
  (ref) => ReconciliationRepository(ref.watch(apiClientProvider)),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'repository_providers.dart';

// ── Estado de autenticación ───────────────────────────────────────────────────

/// Estado de la sesión JWT.
/// [profile] = null → no autenticado.
class AuthState {
  const AuthState({this.profile, this.isLoading = false});

  final Profile? profile;
  final bool isLoading;

  bool get isAuthenticated => profile != null;

  AuthState copyWith({Profile? profile, bool? isLoading, bool clearProfile = false}) =>
      AuthState(
        profile: clearProfile ? null : (profile ?? this.profile),
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final profile = await repo.fetchCurrentProfile();
    return AuthState(profile: profile);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      return AuthState(profile: result.profile);
    });
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).register(
        nombre: nombre,
        email: email,
        password: password,
      );
      return AuthState(profile: result.profile);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthState());
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Perfil del usuario autenticado. Null si no hay sesión.
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.profile;
});

/// True si hay sesión activa.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;
});

/// True si la sesión expiró inesperadamente.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/boss/boss_home.dart';
import '../../screens/boss/catalog_screen.dart';
import '../../screens/boss/employees_screen.dart';
import '../../screens/boss/reconciliation_screen.dart';
import '../../screens/employee/employee_home.dart';
import '../../screens/employee/employee_sales_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/onboarding/create_business_screen.dart';
import '../../screens/onboarding/join_business_screen.dart';

// ── Route names ───────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const createBusiness = '/onboarding/create';
  static const joinBusiness = '/onboarding/join';
  static const bossHome = '/boss';
  static const catalog = '/boss/catalog';
  static const reconciliation = '/boss/reconciliation';
  static const employees = '/boss/employees';
  static const employeeHome = '/employee';
  static const employeeSales = '/employee/sales';
}

// ── RouterNotifier: bridges Riverpod → GoRouter refreshListenable ────────────

final routerNotifierProvider = NotifierProvider<_RouterNotifier, void>(
  _RouterNotifier.new,
);

class _RouterNotifier extends Notifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    ref.listen(authNotifierProvider, (_, __) => _routerListener?.call());
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) {
    if (_routerListener == listener) _routerListener = null;
  }
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);

      // Mientras carga la sesión inicial, no redirigir
      if (authAsync.isLoading) return null;

      final profile = authAsync.valueOrNull?.profile;
      final loc = state.matchedLocation;

      final isOnAuth = loc == AppRoutes.login || loc == AppRoutes.register;
      final isOnOnboarding = loc.startsWith(AppRoutes.onboarding);

      // Sin sesión → solo puede estar en /login o /register
      if (profile == null) {
        return isOnAuth ? null : AppRoutes.login;
      }

      // Autenticado pero sin negocio → onboarding obligatorio
      if (!profile.hasCompletedOnboarding) {
        return isOnOnboarding ? null : AppRoutes.onboarding;
      }

      // Con perfil completo → no puede estar en auth ni onboarding
      if (isOnAuth || isOnOnboarding) {
        return profile.isBoss ? AppRoutes.bossHome : AppRoutes.employeeHome;
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateBusinessScreen(),
          ),
          GoRoute(path: 'join', builder: (_, __) => const JoinBusinessScreen()),
        ],
      ),

      // ── Boss ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.bossHome,
        builder: (_, __) => const BossHome(),
        routes: [
          GoRoute(path: 'catalog', builder: (_, __) => const CatalogScreen()),
          GoRoute(
            path: 'reconciliation',
            builder: (_, __) => const ReconciliationScreen(),
          ),
          GoRoute(
            path: 'employees',
            builder: (_, __) => const EmployeesScreen(),
          ),
        ],
      ),

      // ── Employee ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.employeeHome,
        builder: (_, __) => const EmployeeHome(),
        routes: [
          GoRoute(
            path: 'sales',
            builder: (_, __) => const EmployeeSalesScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.error}')),
    ),
  );
});

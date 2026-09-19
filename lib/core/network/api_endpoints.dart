/// Todas las rutas del backend NestJS.
/// Cambiar [baseUrl] según el entorno de ejecución.
abstract class ApiEndpoints {
  /// URL base del backend (puerto 4000, para no chocar con QRWallet). Override:
  ///   `flutter run --dart-define=API_BASE_URL=http://HOST:4000/api`
  /// Default = alias del emulador Android hacia el localhost de la Mac
  /// (no cambia con el Wi-Fi). Dispositivo físico: pasar la IP LAN de la Mac.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Users / Empleados
  static const String employees = '/users/employees';
  static String removeEmployee(String id) => '/users/$id';

  // Businesses
  static const String businessesCreate = '/businesses';
  static const String businessesJoin = '/businesses/join';
  static const String businessesLookup = '/businesses/lookup';
  static const String businessesMe = '/businesses/me';

  // Products
  static const String products = '/products';
  static String product(String id) => '/products/$id';

  // Sales
  static const String sales = '/sales';
  static const String salesMe = '/sales/me';

  // Notifications
  static const String notifications = '/notifications';

  // Reconciliation
  static const String reconciliationRun = '/reconciliation/run';
  static String reconciliationItems(String id) =>
      '/reconciliation/$id/items';
  static String reconciliation(String id) => '/reconciliation/$id';
}

import 'package:dio/dio.dart';
import 'api_endpoints.dart';

/// Convierte una excepción de red/API en un mensaje legible para el usuario.
String apiErrorMessage(Object error) {
  if (error is! DioException) return error.toString();

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'No se pudo conectar con el servidor (${ApiEndpoints.baseUrl})';
    default:
      break;
  }

  // NestJS responde { message: string | string[] }
  final data = error.response?.data;
  final message = data is Map ? data['message'] : null;
  if (message is String) return message;
  if (message is List) return message.join('\n');
  return error.message ?? 'Error inesperado';
}

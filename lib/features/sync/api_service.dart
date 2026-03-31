import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../sms/data/sms_model.dart';

class SyncResult {
  final int queued;
  final String? error;
  final bool success;

  SyncResult({required this.queued, this.error, required this.success});
}

class ApiService {
  final AuthService authService;

  late final Dio _dio;

  ApiService({required this.authService}) {
    _dio = Dio(BaseOptions(
      baseUrl: AuthService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh
          final newToken = await authService.refreshAccessToken();
          if (newToken != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<SyncResult> syncTransactions({
    required String deviceId,
    required List<Transaction> transactions,
  }) async {
    if (transactions.isEmpty) {
      return SyncResult(queued: 0, success: true);
    }

    try {
      final messages = transactions
          .map((t) => {
                'sender': t.sender,
                'body': t.rawMessage,
                'timestamp': t.dateTime.toIso8601String(),
              })
          .toList();

      final response = await _dio.post(
        '/api/v1/ingestion/sms/',
        data: {
          'device_id': deviceId,
          'messages': messages,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final queued = data?['data']?['queued'] as int? ?? messages.length;

      return SyncResult(queued: queued, success: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Sync failed';
      return SyncResult(queued: 0, error: msg, success: false);
    } catch (e) {
      return SyncResult(queued: 0, error: e.toString(), success: false);
    }
  }

  Future<Map<String, dynamic>?> getSummary() async {
    try {
      final response = await _dio.get('/api/v1/analytics/summary/');
      return response.data?['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
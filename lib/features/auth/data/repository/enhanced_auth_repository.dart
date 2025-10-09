import '../../core/architecture/base_repository.dart';
import '../../core/architecture/result.dart';
import '../../core/network/enhanced_http_client.dart';
import '../auth/data/data_source/auth_api_service.dart';
import '../auth/domain/repository/auth_repository.dart';

class EnhancedAuthRepository extends BaseRepository implements AuthRepository {
  final AuthApiService authApiService;

  EnhancedAuthRepository({
    required this.authApiService,
    required super.httpClient,
  });

  @override
  Future<Result<Map<String, dynamic>>> sendCode(String phoneNumber) async {
    return executeApiCall(
      () async {
        final result = await httpClient.post<Map<String, dynamic>>(
          'user/pin/create/',
          data: {'mobile_number': phoneNumber},
          transformer: (response) => validateAndExtractData(response),
        );
        
        return result;
      },
      operationName: 'sendCode',
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> verifyCode(String phoneNumber, String code) async {
    return executeApiCall(
      () async {
        final result = await httpClient.post<Map<String, dynamic>>(
          'user/pin/verify/',
          data: {
            'mobile_number': phoneNumber,
            'pin': code,
          },
          transformer: (response) => validateAndExtractData(response),
        );
        
        return result;
      },
      operationName: 'verifyCode',
    );
  }

  @override
  Future<Result<void>> logout() async {
    return executeApiCall(
      () async {
        // Clear local storage first
        await _clearLocalAuthData();
        
        // Optionally call logout endpoint if needed
        final result = await httpClient.post<void>(
          'user/logout/',
          transformer: (_) => null,
        );
        
        return result;
      },
      operationName: 'logout',
    );
  }

  Future<void> _clearLocalAuthData() async {
    // Implementation would clear secure storage
    // This is a placeholder for the actual implementation
  }
}
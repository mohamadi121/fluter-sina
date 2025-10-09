import '../architecture/result.dart';
import '../network/enhanced_http_client.dart';

abstract class BaseRepository {
  final EnhancedHttpClient httpClient;

  BaseRepository({required this.httpClient});

  Future<Result<T>> executeApiCall<T>(
    Future<Result<T>> Function() apiCall, {
    String? operationName,
  }) async {
    try {
      final result = await apiCall();
      
      if (operationName != null && result.isSuccess) {
        _logOperation(operationName, 'success');
      } else if (operationName != null && result.isFailure) {
        _logOperation(operationName, 'failed: ${result.errorOrNull}');
      }
      
      return result;
    } catch (error, stackTrace) {
      if (operationName != null) {
        _logOperation(operationName, 'error: $error');
      }
      
      return Failure(UnknownError(
        'Repository operation failed',
        originalError: error,
        stackTrace: stackTrace,
      ));
    }
  }

  void _logOperation(String operation, String status) {
    // In debug mode only
    assert(() {
      print('[$runtimeType] $operation: $status');
      return true;
    }());
  }

  T transformResponse<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response is Map<String, dynamic>) {
      return fromJson(response);
    } else if (response is List) {
      throw const ValidationError('Expected object but received array');
    } else {
      throw ValidationError('Invalid response format: ${response.runtimeType}');
    }
  }

  List<T> transformResponseList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response is List) {
      return response
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } else if (response is Map<String, dynamic>) {
      throw const ValidationError('Expected array but received object');
    } else {
      throw ValidationError('Invalid response format: ${response.runtimeType}');
    }
  }

  Map<String, dynamic> validateAndExtractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final success = response['success'];
      
      if (success == true) {
        return response['data'] as Map<String, dynamic>? ?? {};
      } else {
        final errorMessage = response['message'] ?? 
                           response['error']?['detail'] ?? 
                           'Unknown error';
        throw ValidationError(errorMessage.toString());
      }
    } else {
      throw const ValidationError('Response is not a valid JSON object');
    }
  }

  List<dynamic> validateAndExtractListData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final success = response['success'];
      
      if (success == true) {
        final data = response['data'];
        if (data is List) {
          return data;
        } else {
          throw const ValidationError('Expected list data but received non-list');
        }
      } else {
        final errorMessage = response['message'] ?? 
                           response['error']?['detail'] ?? 
                           'Unknown error';
        throw ValidationError(errorMessage.toString());
      }
    } else {
      throw const ValidationError('Response is not a valid JSON object');
    }
  }
}
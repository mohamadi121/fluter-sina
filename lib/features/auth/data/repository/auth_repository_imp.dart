import 'package:asood/core/architecture/result.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/auth/data/data_source/auth_api_service.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImp implements AuthRepository {
  final AuthApiService authApiService;

  AuthRepositoryImp(this.authApiService);

  @override
  Future<Result<void>> logout() async {
    try {
      final response = await authApiService.logout();
      if (response is Success) {
        return const Result.success(null);
      } else if (response is Failure) {
        return Result.failure(Failure(
          code: response.code,
          errorResponse: response.errorResponse,
        ));
      } else {
        return const Result.failure(Failure(
          code: -1,
          errorResponse: 'Unknown error occurred',
        ));
      }
    } catch (e) {
      return Result.failure(Failure(
        code: -1,
        errorResponse: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> sendCode(String phoneNumber) async {
    try {
      final response = await authApiService.userAuth(phoneNumber);
      if (response is Success) {
        return const Result.success(null);
      } else if (response is Failure) {
        return Result.failure(Failure(
          code: response.code,
          errorResponse: response.errorResponse,
        ));
      } else {
        return const Result.failure(Failure(
          code: -1,
          errorResponse: 'Unknown error occurred',
        ));
      }
    } catch (e) {
      return Result.failure(Failure(
        code: -1,
        errorResponse: e.toString(),
      ));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> verifyCode(String phoneNumber, String code) async {
    try {
      final response = await authApiService.verifyUser(phoneNumber, code);
      if (response is Success) {
        return Result.success(response.response as Map<String, dynamic>);
      } else if (response is Failure) {
        return Result.failure(Failure(
          code: response.code,
          errorResponse: response.errorResponse,
        ));
      } else {
        return const Result.failure(Failure(
          code: -1,
          errorResponse: 'Unknown error occurred',
        ));
      }
    } catch (e) {
      return Result.failure(Failure(
        code: -1,
        errorResponse: e.toString(),
      ));
    }
  }
}

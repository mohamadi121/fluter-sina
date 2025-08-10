import 'package:asoud/core/http_client/api_status.dart';
import 'package:asoud/core/network/app_result.dart' as core;
import 'package:asoud/core/network/app_error.dart';
import 'package:asoud/features/auth/data/data_source/auth_api_service.dart';
import 'package:asoud/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImp implements AuthRepository {
  final AuthApiService authApiService;

  AuthRepositoryImp(this.authApiService);

  @override
  //logout user
  Future<dynamic> logout() async {
    var res = await authApiService.logout();
    if (res is Success) {
      return res;
    } else {
      return res;
    }
  }

  @override
  Future sendCode(String number) async {
    var res = await authApiService.userAuth(number);
    if (res is Success) {
      return res;
    } else {
      return res;
    }
  }

  @override
  Future verifyCode(String number, String code) async {
    var res = await authApiService.verifyUser(number, code);
    if (res is Success) {
      return res;
    } else {
      return res;
    }
  }

  // Migrated methods using AppResult pattern
  @override
  Future<core.AppResult<void>> userAuth(String number) async {
    try {
      var res = await authApiService.userAuth(number);
      if (res is Success) {
        return core.Success<void>(null);
      } else {
        return core.Failure<void>(NetworkError(message: 'Authentication failed'));
      }
    } catch (e) {
      return core.Failure<void>(NetworkError(message: e.toString()));
    }
  }

  @override
  Future<core.AppResult<String>> verifyUser(String number, String code) async {
    try {
      var res = await authApiService.verifyUser(number, code);
      if (res is Success) {
        return core.Success<String>('verified');
      } else {
        return core.Failure<String>(NetworkError(message: 'Verification failed'));
      }
    } catch (e) {
      return core.Failure<String>(NetworkError(message: e.toString()));
    }
  }

  @override
  Future<core.AppResult<dynamic>> logoutUser() async {
    try {
      var res = await authApiService.logout();
      if (res is Success) {
        return core.Success<dynamic>(true);
      } else {
        return core.Failure<dynamic>(NetworkError(message: 'Logout failed'));
      }
    } catch (e) {
      return core.Failure<dynamic>(NetworkError(message: e.toString()));
    }
  }
}

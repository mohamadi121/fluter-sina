import 'package:asood/features/auth/data/data_source/auth_api_service.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImp implements AuthRepository {
  final AuthApiService authApiService;

  AuthRepositoryImp(this.authApiService);

  @override
  Future<dynamic> sendCode(String number) {
    return authApiService.userAuth(number);
  }

  @override
  Future<dynamic> verifyCode(String number, String code) {
    return authApiService.verifyUser(number, code);
  }
}

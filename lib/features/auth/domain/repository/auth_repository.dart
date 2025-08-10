import 'package:asoud/core/network/app_result.dart' as core;

abstract class AuthRepository {
  // Legacy methods (deprecated, use migrated versions)
  Future<dynamic> sendCode(String number); 
  Future<dynamic> verifyCode(String number, String code); 
  Future<dynamic> logout(); 

  // Migrated methods using AppResult pattern (preferred)
  Future<core.AppResult<void>> userAuth(String number);
  Future<core.AppResult<String>> verifyUser(String number, String code);
  Future<core.AppResult<dynamic>> logoutUser();
}

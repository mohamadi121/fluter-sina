import 'package:dio/dio.dart';
import 'app_result.dart';
import 'app_error.dart';
import 'app_result.dart';

abstract class ApiExecutor {
  final Dio dio;
  ApiExecutor(this.dio);

  Future<AppResult<R>> guardFuture<R>(Future<Response> future, R Function(dynamic json) parser) async {
    try {
      final response = await future;
      return ResultMapper.fromEnvelope<R>(response, dataParser: parser);
    } on DioException catch (e) {
      return Failure(AppErrorMapper.fromDio(e));
    } catch (e) {
      return Failure(UnknownError(message: 'خطای ناشناخته', originalError: e));
    }
  }
}

class AppErrorMapper {
  static AppError fromDio(DioException e) => ErrorHandler.handleDioError(e);
}

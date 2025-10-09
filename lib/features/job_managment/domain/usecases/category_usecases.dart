import 'package:asood/core/domain/usecase.dart';
import 'package:asood/core/architecture/result.dart';
import 'package:asood/features/job_managment/domain/repository/category_repository.dart';

/// Get Category List UseCase
class GetCategoryListUseCase extends NoParamsUseCase<List<dynamic>> {
  final CategoryRepository repository;

  GetCategoryListUseCase(this.repository);

  @override
  Future<Result<List<dynamic>>> call(NoParams params) async {
    try {
      final result = await repository.getCategoryList();

      if (result is Success) {
        return Result.success(result.response as List<dynamic>);
      } else if (result is Failure) {
        return Result.failure(result);
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

/// Get Main Sub Category List UseCase
class GetMainSubCategoryListUseCase extends UseCase<List<dynamic>, GetMainSubCategoryParams> {
  final CategoryRepository repository;

  GetMainSubCategoryListUseCase(this.repository);

  @override
  Future<Result<List<dynamic>>> call(GetMainSubCategoryParams params) async {
    try {
      final result = await repository.getMainSubCategoryList(params.categoryId);

      if (result is Success) {
        return Result.success(result.response as List<dynamic>);
      } else if (result is Failure) {
        return Result.failure(result);
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

/// Get Sub Category List UseCase
class GetSubCategoryListUseCase extends UseCase<List<dynamic>, GetSubCategoryParams> {
  final CategoryRepository repository;

  GetSubCategoryListUseCase(this.repository);

  @override
  Future<Result<List<dynamic>>> call(GetSubCategoryParams params) async {
    try {
      final result = await repository.getSubCategoryList(params.subCategoryId);

      if (result is Success) {
        return Result.success(result.response as List<dynamic>);
      } else if (result is Failure) {
        return Result.failure(result);
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

// UseCase Parameters
class GetMainSubCategoryParams extends UseCaseParams {
  final String categoryId;

  const GetMainSubCategoryParams({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class GetSubCategoryParams extends UseCaseParams {
  final String subCategoryId;

  const GetSubCategoryParams({required this.subCategoryId});

  @override
  List<Object?> get props => [subCategoryId];
}
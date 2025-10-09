import 'package:asood/core/domain/usecase.dart';
import 'package:asood/core/architecture/result.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:asood/features/market/data/model/product_model.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';

/// Get Product List UseCase
class GetProductListUseCase extends UseCase<List<dynamic>, GetProductListParams> {
  final ProductRepository repository;

  GetProductListUseCase(this.repository);

  @override
  Future<Result<List<dynamic>>> call(GetProductListParams params) async {
    try {
      final result = await repository.productList(params.productId);

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

/// Create Product UseCase
class CreateProductUseCase extends UseCase<Map<String, dynamic>, CreateProductParams> {
  final ProductRepository repository;

  CreateProductUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateProductParams params) async {
    try {
      final result = await repository.createProduct(params.product);

      if (result is Success) {
        return Result.success(result.response as Map<String, dynamic>);
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

/// Create Product Discount UseCase
class CreateProductDiscountUseCase extends UseCase<Map<String, dynamic>, CreateProductDiscountParams> {
  final ProductRepository repository;

  CreateProductDiscountUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateProductDiscountParams params) async {
    try {
      final result = await repository.createProductDiscount(
        params.productId,
        params.position,
        params.percent,
        params.days,
      );

      if (result is Success) {
        return Result.success(result.response as Map<String, dynamic>);
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

/// Create Market Theme UseCase
class CreateMarketThemeUseCase extends UseCase<Map<String, dynamic>, CreateMarketThemeParams> {
  final ProductRepository repository;

  CreateMarketThemeUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateMarketThemeParams params) async {
    try {
      final result = await repository.createMarketTheme(params.marketId, params.order);

      if (result is Success) {
        return Result.success(result.response as Map<String, dynamic>);
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

/// Get Market Theme UseCase
class GetMarketThemeUseCase extends UseCase<Map<String, dynamic>, GetMarketThemeParams> {
  final ProductRepository repository;

  GetMarketThemeUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(GetMarketThemeParams params) async {
    try {
      final result = await repository.getMarketTheme(params.marketId);

      if (result is Success) {
        return Result.success(result.response as Map<String, dynamic>);
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

/// Update Market Theme UseCase
class UpdateMarketThemeUseCase extends UseCase<Map<String, dynamic>, UpdateMarketThemeParams> {
  final ProductRepository repository;

  UpdateMarketThemeUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(UpdateMarketThemeParams params) async {
    try {
      final result = await repository.updateMarketTheme(
        productId: params.productId,
        themeId: params.themeId,
        themeIndex: params.themeIndex,
      );

      if (result is Success) {
        return Result.success(result.response as Map<String, dynamic>);
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
class GetProductListParams extends UseCaseParams {
  final String productId;

  const GetProductListParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class CreateProductParams extends UseCaseParams {
  final ProductModel product;

  const CreateProductParams({required this.product});

  @override
  List<Object?> get props => [product];
}

class CreateProductDiscountParams extends UseCaseParams {
  final String productId;
  final PositionEnum position;
  final int percent;
  final int days;

  const CreateProductDiscountParams({
    required this.productId,
    required this.position,
    required this.percent,
    required this.days,
  });

  @override
  List<Object?> get props => [productId, position, percent, days];
}

class CreateMarketThemeParams extends UseCaseParams {
  final String marketId;
  final int order;

  const CreateMarketThemeParams({
    required this.marketId,
    required this.order,
  });

  @override
  List<Object?> get props => [marketId, order];
}

class GetMarketThemeParams extends UseCaseParams {
  final String marketId;

  const GetMarketThemeParams({required this.marketId});

  @override
  List<Object?> get props => [marketId];
}

class UpdateMarketThemeParams extends UseCaseParams {
  final String productId;
  final String themeId;
  final String themeIndex;

  const UpdateMarketThemeParams({
    required this.productId,
    required this.themeId,
    required this.themeIndex,
  });

  @override
  List<Object?> get props => [productId, themeId, themeIndex];
}
import 'package:asood/core/domain/usecase.dart';
import 'package:asood/core/architecture/result.dart';
import 'package:asood/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:asood/features/create_workspace/data/model/market_contact.dart';
import 'package:asood/features/create_workspace/data/model/market_schedule.dart';
import 'package:asood/features/vendor/data/model/market_location_model.dart';
import 'package:asood/core/models/theme_model.dart';
import 'package:image_picker/image_picker.dart';

/// Create Market Base UseCase
class CreateMarketUseCase extends UseCase<Map<String, dynamic>, CreateMarketParams> {
  final CreateMarketRepository repository;

  CreateMarketUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateMarketParams params) async {
    try {
      final result = await repository.createMarketBase(
        params.type,
        params.businessId,
        params.name,
        params.description,
        params.subCategory,
        params.slogan,
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

/// Get Market List UseCase
class GetMarketListUseCase extends NoParamsUseCase<List<dynamic>> {
  final CreateMarketRepository repository;

  GetMarketListUseCase(this.repository);

  @override
  Future<Result<List<dynamic>>> call(NoParams params) async {
    try {
      final result = await repository.getMarketList();

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

/// Create Market Contact UseCase
class CreateMarketContactUseCase extends UseCase<Map<String, dynamic>, CreateMarketContactParams> {
  final CreateMarketRepository repository;

  CreateMarketContactUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateMarketContactParams params) async {
    try {
      final result = await repository.createMarketContact(params.marketContact);

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

/// Create Market Location UseCase
class CreateMarketLocationUseCase extends UseCase<Map<String, dynamic>, CreateMarketLocationParams> {
  final CreateMarketRepository repository;

  CreateMarketLocationUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateMarketLocationParams params) async {
    try {
      final result = await repository.createMarketLocation(params.marketLocation);

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

/// Create Market Schedule UseCase
class CreateMarketScheduleUseCase extends UseCase<Map<String, dynamic>, CreateMarketScheduleParams> {
  final CreateMarketRepository repository;

  CreateMarketScheduleUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(CreateMarketScheduleParams params) async {
    try {
      final result = await repository.createSchedule(params.scheduleModel);

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

/// Upload Market Logo UseCase
class UploadMarketLogoUseCase extends UseCase<Map<String, dynamic>, UploadMarketLogoParams> {
  final CreateMarketRepository repository;

  UploadMarketLogoUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(UploadMarketLogoParams params) async {
    try {
      final result = await repository.uploadMarketLogo(params.imageFile, params.marketId);

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

/// Set Market Theme UseCase
class SetMarketThemeUseCase extends UseCase<Map<String, dynamic>, SetMarketThemeParams> {
  final CreateMarketRepository repository;

  SetMarketThemeUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(SetMarketThemeParams params) async {
    try {
      final result = await repository.setMarketTheme(params.marketId, params.themeModel);

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
class CreateMarketParams extends UseCaseParams {
  final String type;
  final String businessId;
  final String name;
  final String description;
  final String subCategory;
  final String slogan;

  const CreateMarketParams({
    required this.type,
    required this.businessId,
    required this.name,
    required this.description,
    required this.subCategory,
    required this.slogan,
  });

  @override
  List<Object?> get props => [type, businessId, name, description, subCategory, slogan];
}

class CreateMarketContactParams extends UseCaseParams {
  final MarketContactModel marketContact;

  const CreateMarketContactParams({required this.marketContact});

  @override
  List<Object?> get props => [marketContact];
}

class CreateMarketLocationParams extends UseCaseParams {
  final MarketLocationModel marketLocation;

  const CreateMarketLocationParams({required this.marketLocation});

  @override
  List<Object?> get props => [marketLocation];
}

class CreateMarketScheduleParams extends UseCaseParams {
  final MarketScheduleModel scheduleModel;

  const CreateMarketScheduleParams({required this.scheduleModel});

  @override
  List<Object?> get props => [scheduleModel];
}

class UploadMarketLogoParams extends UseCaseParams {
  final XFile imageFile;
  final String marketId;

  const UploadMarketLogoParams({
    required this.imageFile,
    required this.marketId,
  });

  @override
  List<Object?> get props => [imageFile, marketId];
}

class SetMarketThemeParams extends UseCaseParams {
  final String marketId;
  final ThemeModel themeModel;

  const SetMarketThemeParams({
    required this.marketId,
    required this.themeModel,
  });

  @override
  List<Object?> get props => [marketId, themeModel];
}
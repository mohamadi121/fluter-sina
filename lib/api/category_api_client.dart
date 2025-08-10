import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/base_response_dto.dart';
import '../core/models/dto/category_dto.dart';

part 'category_api_client.g.dart';

@RestApi()
abstract class CategoryApiClient {
  factory CategoryApiClient(Dio dio, {String baseUrl}) = _CategoryApiClient;

  /// Get all category groups
  @GET('/category/group/list/')
  Future<BaseResponseDto<List<CategoryGroupDto>>> getCategoryGroups();

  /// Get categories by group ID
  @GET('/category/list/{groupId}')
  Future<BaseResponseDto<List<CategoryDto>>> getCategories(
    @Path('groupId') String groupId,
  );
}

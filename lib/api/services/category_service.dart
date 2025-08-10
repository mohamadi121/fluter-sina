import '../../core/models/dto/category_dto.dart';
import '../../core/models/dto/base_response_dto.dart';
import '../../core/network/app_error.dart';
import '../category_api_client.dart';

/// Service for handling category API responses
class CategoryApiService {
  final CategoryApiClient _categoryApiClient;

  CategoryApiService(this._categoryApiClient);

  /// Get all category groups
  Future<List<CategoryGroupDto>> getCategoryGroups() async {
    try {
      final response = await _categoryApiClient.getCategoryGroups();
      
      if (!response.success || response.data == null) {
        throw _mapErrorFromResponse(response);
      }
      
      return response.data!;
    } catch (e) {
      if (e is AppError) rethrow;
      throw UnknownError(
        message: 'خطا در دریافت گروه‌های دسته‌بندی',
        originalError: e,
      );
    }
  }

  /// Get categories by group ID  
  Future<List<CategoryDto>> getCategories(String groupId) async {
    try {
      final response = await _categoryApiClient.getCategories(groupId);
      
      if (!response.success || response.data == null) {
        throw _mapErrorFromResponse(response);
      }
      
      return response.data!;
    } catch (e) {
      if (e is AppError) rethrow;
      throw UnknownError(
        message: 'خطا در دریافت دسته‌بندی‌ها',
        originalError: e,
      );
    }
  }

  /// Map API error response to AppError
  AppError _mapErrorFromResponse(BaseResponseDto response) {
    switch (response.code) {
      case 401:
        return AuthError.unauthorized();
      case 404:
        return const BusinessError(
          message: 'دسته‌بندی مورد نظر یافت نشد',
          code: '404',
        );
      case 500:
        return const NetworkError(
          message: 'خطا در سرور، لطفاً بعداً تلاش کنید',
          code: '500',
        );
      default:
        return BusinessError(
          message: response.error?.toString() ?? 'خطای ناشناخته',
          code: response.code.toString(),
        );
    }
  }
}

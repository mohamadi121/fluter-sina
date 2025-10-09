import 'package:asood/core/architecture/result.dart';

abstract class CategoryRepository {
  Future<Result<List<dynamic>>> getCategoryList();

  Future<Result<List<dynamic>>> getMainSubCategoryList(String categoryId);

  Future<Result<List<dynamic>>> getSubCategoryList(String subCategoryId);
}

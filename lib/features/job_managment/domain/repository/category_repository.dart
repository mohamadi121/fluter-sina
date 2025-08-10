abstract class CategoryRepository {
  Future<dynamic> getCategoryList() async {}

  Future<dynamic> getMainSubCategoryList(String categoryId) async {}

  Future<dynamic> getSubCategoryList(String subCategoryId) async {}

  // Additional methods needed by JobmanagmentBloc
  Future<dynamic> groups() async {}

  Future<dynamic> categories(String categoryId) async {}

  Future<dynamic> subCategories(String subCategoryId) async {}
}

import 'package:asoud/features/job_managment/data/data_source/category_api_service.dart';
import 'package:asoud/features/job_managment/domain/repository/category_repository.dart';

class CategoryRepositoryImp implements CategoryRepository {
  final CategoryApiService categoryApiService;
  CategoryRepositoryImp(this.categoryApiService);

  @override
  Future getCategoryList() async {
    return await categoryApiService.getCategoryList();
  }

  @override
  Future getMainSubCategoryList(String categoryId) async {
    return await categoryApiService.getMainSubCategoryList(categoryId);
  }

  @override
  Future getSubCategoryList(String subCategoryId) async {
    return await categoryApiService.getSubCategoryList(subCategoryId);
  }

  // Additional methods needed by JobmanagmentBloc
  @override
  Future groups() async {
    // TODO: Implement groups functionality
    return await getCategoryList(); // For now, delegate to getCategoryList
  }

  @override
  Future categories(String categoryId) async {
    // TODO: Implement categories functionality
    return await getMainSubCategoryList(categoryId); // For now, delegate to getMainSubCategoryList
  }

  @override
  Future subCategories(String subCategoryId) async {
    // TODO: Implement subCategories functionality  
    return await getSubCategoryList(subCategoryId); // For now, delegate to getSubCategoryList
  }
}

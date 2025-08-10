import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/features/job_managment/data/model/category_model.dart';
import 'package:bloc/bloc.dart';
import 'package:asoud/features/job_managment/domain/repository/category_repository.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/models/dto/category_dto.dart';

part 'jobmanagment_event.dart';
part 'jobmanagment_state.dart';

class JobmanagmentBloc extends Bloc<JobmanagmentEvent, JobmanagmentState> {
  final CategoryRepository categoryRepository;
  JobmanagmentBloc(this.categoryRepository) : super(JobmanagmentState.initial()) {
    on<ResetJobManagmentBloc>((event, emit) => emit(JobmanagmentState.initial()));
    on<ChangeTabView>((event, emit) => emit(state.copyWith(activeTabIndex: event.activeTabIndex)));
    on<ChangeCategoryIndex>((event, emit) => emit(state.copyWith(activeCategoryId: event.activeCategoryId)));
    on<ChangeSelectedCategoryName>((event, emit) => emit(state.copyWith(selectedCategoryName: event.selectedCat)));
    on<LoadCategory>(_getCategory);
    on<LoadMainSubCategory>(_getMainSubCategory);
    on<ChangeSubCategoryIndex>((event, emit) => emit(state.copyWith(activeSubCategoryIndex: event.activeSubCategoryIndex)));
    on<LoadSubCategory>(_getSubCategory);
  }

  // list of category groups
  Future<void> _getCategory(LoadCategory event, Emitter<JobmanagmentState> emit) async {
    emit(state.copyWith(status: const UiLoading(), activeTabIndex: 0));
    final res = await categoryRepository.groups();
    if (res is Success<List<CategoryGroupDto>>) {
      final groups = res.data
          .map((g) => CategoryModel(id: g.id, title: g.title))
          .toList();
      emit(state.copyWith(status: const UiSuccess(), categoryList: groups));
    } else {
      emit(state.copyWith(status: UiError(res.error.message)));
    }
  }

  // list of categories (main sub category in old naming)
  Future<void> _getMainSubCategory(LoadMainSubCategory event, Emitter<JobmanagmentState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    final res = await categoryRepository.categories(event.categoryId);
    if (res is Success<List<CategoryDto>>) {
      final mainSubCategory = res.data
          .map((c) => CategoryModel(id: c.id, title: c.title))
          .toList();
      emit(state.copyWith(status: const UiSuccess(), mainSubCategoryList: mainSubCategory));
    } else {
      emit(state.copyWith(status: UiError(res.error.message)));
    }
  }

  // list of sub categories
  Future<void> _getSubCategory(LoadSubCategory event, Emitter<JobmanagmentState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    final res = await categoryRepository.subCategories(event.subCategoryId);
    if (res is Success<List<SubCategoryDto>>) {
      final subCategory = res.data
          .map((s) => CategoryModel(id: s.id, title: s.title))
          .toList();
      emit(state.copyWith(status: const UiSuccess(), subCategoryList: subCategory));
    } else {
      emit(state.copyWith(status: UiError(res.error.message)));
    }
  }
}

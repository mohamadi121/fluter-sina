part of 'jobmanagment_bloc.dart';

class JobmanagmentState extends BaseBlocState<List<CategoryModel>> {
  final int activeTabIndex;
  final String activeCategoryId;
  final List<CategoryModel> categoryList;
  final List<CategoryModel> mainSubCategoryList;
  final String activeSubCategoryIndex;
  final List<CategoryModel> subCategoryList;
  final String selectedCategoryName;

  const JobmanagmentState({
    this.activeTabIndex = 0,
    this.activeCategoryId = "",
    this.categoryList = const [],
    this.mainSubCategoryList = const [],
    this.activeSubCategoryIndex = "",
    this.subCategoryList = const [],
    this.selectedCategoryName = "",
    super.status = StateStatus.initial,
    super.error,
    super.data,
  });

  factory JobmanagmentState.initial() {
    return const JobmanagmentState(
      activeTabIndex: 0,
      activeCategoryId: "",
      categoryList: [],
      mainSubCategoryList: [],
      activeSubCategoryIndex: "",
      subCategoryList: [],
      selectedCategoryName: "",
      status: StateStatus.initial,
    );
  }

  @override
  JobmanagmentState copyWith({
    int? activeTabIndex,
    String? activeCategoryId,
    List<CategoryModel>? categoryList,
    List<CategoryModel>? mainSubCategoryList,
    String? activeSubCategoryIndex,
    List<CategoryModel>? subCategoryList,
    String? selectedCategoryName,
    StateStatus? status,
    String? error,
    List<CategoryModel>? data,
  }) {
    return JobmanagmentState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      categoryList: categoryList ?? this.categoryList,
      mainSubCategoryList: mainSubCategoryList ?? this.mainSubCategoryList,
      activeSubCategoryIndex: activeSubCategoryIndex ?? this.activeSubCategoryIndex,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      status: status ?? this.status,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
    activeTabIndex,
    activeCategoryId,
    categoryList,
    mainSubCategoryList,
    activeSubCategoryIndex,
    subCategoryList,
    selectedCategoryName,
    status,
    error,
    data,
  ];
}

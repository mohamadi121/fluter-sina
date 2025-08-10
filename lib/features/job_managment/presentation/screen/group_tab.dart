import 'package:asoud/core/helper/snack_bar_util.dart';
import 'package:asoud/features/job_managment/data/model/category_model.dart';
import 'package:asoud/features/job_managment/presentation/bloc/jobmanagment_bloc.dart';
import 'package:asoud/features/job_managment/presentation/widgets/category_builder.dart';
import 'package:asoud/features/job_managment/presentation/widgets/edit_cat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asoud/core/constants/constants.dart';
import 'package:asoud/core/ui/ui_status.dart';

import 'package:asoud/core/widgets/custom_button.dart';

class GroupTab extends StatefulWidget {
  final JobmanagmentBloc bloc;
  const GroupTab({required this.bloc, super.key});

  @override
  State<GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<GroupTab> {
  String selectedCategoryId = "0";

  late JobmanagmentBloc catBloc;

  @override
  void initState() {
    super.initState();
    // name.text = widget.bloc.state.name;
    // businessId.text = widget.bloc.state.businessId;
    // description.text = widget.bloc.state.description;
    // slogan.text = widget.bloc.state.slogan;
    // selectedValue = widget.bloc.state.marketType;
    // inProcess();
    //idCode.text =  widget.bloc.state.idCode;
  }

  // void inProcess() async {
  //   String tabIndex = await SecureStorage.readSecureStorage('market_id');
  //   String marketId = await SecureStorage.readSecureStorage(
  //     'marketActiveTabIndex',
  //   );

  //   if (tabIndex != 'ND' && marketId != 'ND') {
  //     isInProcess = true;
  //   } else {
  //     isInProcess = false;
  //     print('object');
  //   }
  // }

  // submit(CreateWorkSpaceBloc bloc) {
  //   if (_formKey.currentState!.validate() &&
  //       bloc.state.marketType.isNotEmpty &&
  //       bloc.state.activeCategoryIndex >= 0) {
  //     bloc.add(
  //       CreateMarket(
  //         businessId: businessId.text,
  //         name: name.text,
  //         description: description.text,
  //         slogan: slogan.text,
  //         marketType: selectedValue,
  //         subCategory: selectedCategoryId,
  //       ),
  //     );

  //     // bloc.add(const ChangeCategoryIndex(activeCategoryIndex: -1));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         backgroundColor: Colora.borderAvatar,
  //         content: Text(
  //           "لطفا تمامی فیلد های لازم را پر نمایید.",
  //           style: TextStyle(color: Colora.scaffold),
  //         ),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<JobmanagmentBloc>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.khorisontal),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BlocConsumer<JobmanagmentBloc, JobmanagmentState>(
              listener: (context, state) {
                if (state.status is UiError) {
                  final msg = (state.status as UiError).message;
                  showSnackBar(context, msg.isNotEmpty ? msg : "مشکلی پیش آمده مجددا تلاش کنید");
                }
              },
              builder: (context, state) {
                if (state.status is UiSuccess) {
                  return Container(
                    width: Dimensions.width,

                    margin: EdgeInsets.only(bottom: Dimensions.height * 0.04),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colora.primaryColor,
                    ),
                    padding: EdgeInsets.all(Dimensions.height * 0.01),
                    child: CategoryBuilder(
                      state: state,
                      onItemTap: (index) {
                        CategoryModel selectedCategory = state.categoryList[index];
                        bloc.add(ChangeCategoryIndex(activeCategoryId: selectedCategory.id!));
                        bloc.add(ChangeTabView(activeTabIndex: 1));
                        bloc.add(LoadMainSubCategory(categoryId: selectedCategory.id!));
                      },
                      categories: state.categoryList,
                    ),
                  );
                }
                if (state.status is UiError) {
                  final msg = (state.status as UiError).message;
                  return Text(msg.isNotEmpty ? msg : state.error);
                }
                return const CircularProgressIndicator(color: Colors.white);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomButton(
                  onPress: () {},
                  text: BlocProvider.of<JobmanagmentBloc>(context).state.status.isLoading ? null : "ویرایش",
                  color: Colora.primaryColor,
                  textColor: Colors.white,
                  height: 40,
                  width: 100,
                  btnWidget: BlocProvider.of<JobmanagmentBloc>(context).state.status.isLoading
                      ? const Center(child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator()))
                      : null,
                ),
                CustomButton(
                  onPress: () => showCustomFormDialog(context),
                  text: BlocProvider.of<JobmanagmentBloc>(context).state.status.isLoading ? null : "افزودن دسته",
                  color: Colora.primaryColor,
                  textColor: Colors.white,
                  height: 40,
                  width: 100,
                  btnWidget: BlocProvider.of<JobmanagmentBloc>(context).state.status.isLoading
                      ? const Center(child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator()))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

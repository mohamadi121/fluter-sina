import 'package:asoud/core/constants/constants.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/widgets/custom_button.dart';
import 'package:asoud/features/job_managment/data/model/category_model.dart';
import 'package:asoud/features/job_managment/presentation/bloc/jobmanagment_bloc.dart';
import 'package:flutter/material.dart';

class CategoryBuilder extends StatelessWidget {
  final JobmanagmentState state;
  final List<CategoryModel> categories;
  final Function(int index) onItemTap;
  const CategoryBuilder({
    super.key,
    required this.state,
    required this.onItemTap,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        CategoryModel selectedCategory = categories[index];
        final loading = state.status.isLoading;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomButton(
            onPress: () { if (!loading) onItemTap(index); },
            text: loading ? null : selectedCategory.title!,
            color: Colors.white,
            textColor: Colora.primaryColor,
            height: 40,
            width: 100,
            btnWidget: loading
                ? const Center(child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white)))
                : null,
          ),
        );
      },
    );
  }
}

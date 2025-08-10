import 'package:asoud/core/constants/constants.dart';
import 'package:asoud/core/router/app_routers.dart';
import 'package:asoud/core/widgets/custom_button.dart';
import 'package:asoud/core/widgets/custom_dialog.dart';
import 'package:asoud/core/widgets/custom_textfield.dart';
import 'package:asoud/features/create_workspace/presentation/bloc/create_workspace_bloc.dart';
import 'package:asoud/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:asoud/core/ui/ui_status.dart';

void paymentDialog(BuildContext context) {
  return CustomDialog(
    context: context,
    title: "انتخاب درگاه",
    widget: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('میخواهید از درگاه آسود استفاده کنید یا درگاه شخصی؟'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomButton(
                onPress: () {
                  Navigator.of(context).pop();
                  CustomDialog(
                    context: context,
                    title: "ثبت درگاه شخصی",
                    widget: Container(
                      height: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('کلید درگاه خود را وارد کنید'),
                          SizedBox(
                            height: 35,
                            child: CustomTextField(
                              controller: TextEditingController(),
                              text: "کد درگاه",
                              hintStyle: const TextStyle(color: Colors.white),
                              color: Colora.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomButton(
                                onPress: () {},
                                text: "ثبت",
                                width: 120,
                                color: Colora.primaryColor,
                                textColor: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              CustomButton(
                                onPress: () {},
                                text: "انصراف",
                                width: 120,
                                color: Colora.primaryColor,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCustomDialog();
                },
                text: "درگاه شخصی",
                width: 90,
                color: Colora.primaryColor,
                textColor: Colors.white,
              ),
              CustomButton(
                onPress: () {
                  WorkspaceBloc workSpace = context.read<WorkspaceBloc>();
                  workSpace.add(LoadStores());
                  if (workSpace.state.status is UiSuccess) {
                    if (workSpace.state.storesList.length == 1) {
                      Navigator.pop(context);
                      context.pushReplacement(AppRoutes.markets);
                      context.push(
                        AppRoutes.storeDetail,
                        extra: workSpace.state.storesList.first,
                      );
                    } else {
                      Navigator.pop(context);
                      context.pushReplacement(AppRoutes.markets);
                    }
                  }
                },
                text: "بعدا",
                width: 90,
                color: Colora.primaryColor,
                textColor: Colors.white,
              ),
              CustomButton(
                onPress: () {
                  CustomDialog(
                    height: 405.0,
                    context: context,
                    title: "پرداخت حق اشتراک",
                    widget: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      child: Column(
                        children: [
                          const Text("مبلغ پرداختی را وارد کنید"),
                          const SizedBox(height: 5),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 35,
                                  width: 180,
                                  child: CustomTextField(
                                    color: Colora.primaryColor.withOpacity(0.5),
                                    controller: TextEditingController(),
                                    text: "کد تخفیف",
                                  ),
                                ),
                                CustomButton(
                                  height: 35,
                                  width: 100,
                                  onPress: () {},
                                  text: "ثبت تخفیف",
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 30,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            height: 200,
                            width: Dimensions.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("مبلغ پرداختی:"),
                                    Text("تومان"),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("مبلغ پرداختی:"),
                                    Text("تومان"),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("مبلغ پرداختی:"),
                                    Text("تومان"),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("مبلغ پرداختی:"),
                                    Text("تومان"),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("مبلغ پرداختی:"),
                                    Text("تومان"),
                                  ],
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomButton(
                                onPress: () {
                                  context.pushReplacement(
                                    AppRoutes.storeDetail,
                                  );
                                },
                                text: "پرداخت",
                                width: 120,
                                color: Colora.primaryColor,
                                textColor: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              CustomButton(
                                onPress: () {},
                                text: "انصراف",
                                width: 120,
                                color: Colora.primaryColor,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).showCustomDialog();
                },
                text: "درگاه آسود",
                width: 90,
                color: Colora.primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    ),
  ).showCustomDialog();
}

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/search_box.dart';
import 'package:asood/core/widgets/simple_bot_navbar.dart';
import 'package:asood/features/inquiry/presentation/blocs/inquiry_list_cubit.dart';
import 'package:asood/features/inquiry/presentation/screens/inquiry_dashboard.dart';
import 'package:asood/features/inquiry/presentation/screens/submit_fee_inquiry.dart';
import 'package:asood/locator.dart';
import 'package:flutter/material.dart';

class InquiryRequestsScreen extends StatefulWidget {
  const InquiryRequestsScreen({super.key});

  @override
  State<InquiryRequestsScreen> createState() => _InquiryRequestsScreenState();
}

class _InquiryRequestsScreenState extends State<InquiryRequestsScreen> {
  final InquiryListCubit _cubit = locator<InquiryListCubit>();

  List<Map<String, dynamic>> inquiries = [];
  List<Map<String, dynamic>> visibleInquiriesButtons = [];

  void getInquiries() async {
    await _cubit.load();
    if (!mounted) {
      return;
    }
    setState(() {
      inquiries = _cubit.state.inquiries;
    });
  }

  void sendData(String send, String id) async {
    final ok = await _cubit.send(id);
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('استعلام جدید با موفقیت ارسال شد'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cubit.state.error ?? 'ارسال ناموفق بود')),
      );
    }
  }

  void dialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colora.scaffold,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.all(Dimensions.width * 0.05),
              decoration: BoxDecoration(
                color: Colora.scaffold,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ارسال استعلام',
                    style: TextStyle(
                      color: Colora.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colora.primaryColor, height: 5),
                  const SizedBox(height: 10),
                  const Text(
                    'کاربر گرامی از چه طریقی قصد ارسال استعلام را دارید ؟',
                    style: TextStyle(color: Colora.primaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colora.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          sendData('sms', id);
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('ارسال پیامک'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colora.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          sendData('chat', id);
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('ارسال توسط آسود'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getInquiries();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: DefaultAppBar(title: 'استعلام ها'),
      body: SafeArea(
        // maintainBottomViewPadding: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: Dimensions.height * 0.02),
                child: SearchBoxWidget(),
              ),
              inquiries.isEmpty
                  ? Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: Dimensions.width * 0.03,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: SizedBox(
                        height: Dimensions.height * 0.15,
                        child: Center(
                          child: Text(
                            'شما استعلامی ندارید',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colora.backgroundSwitch,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children: [
                      ...inquiries.map((inquiry) {
                        return Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: Dimensions.width * 0.03,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    if (visibleInquiriesButtons.contains(
                                      inquiry,
                                    )) {
                                      setState(() {
                                        visibleInquiriesButtons.removeAt(
                                          visibleInquiriesButtons.indexOf(
                                            inquiry,
                                          ),
                                        );
                                      });
                                    } else {
                                      setState(() {
                                        visibleInquiriesButtons.add(inquiry);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(10),

                                    height: Dimensions.height * 0.15,
                                    decoration: BoxDecoration(
                                      color: Colora.backgroundSwitch,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          height: Dimensions.height * 0.12,
                                          width: Dimensions.height * 0.12,
                                          decoration: BoxDecoration(
                                            color: Colora.lightBlue,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child:
                                              inquiry['images'].isEmpty
                                                  ? Container()
                                                  : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                    child: Image.network(
                                                      'https://asoud.ir/${inquiry['images'][0]['image']}',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                        ),
                                        SizedBox(
                                          height: Dimensions.height * 0.12,
                                          width: Dimensions.width * 0.6,
                                          child: Column(
                                            children: [
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Text(
                                                  inquiry['name'].length < 20
                                                      ? inquiry['name']
                                                      : inquiry['name']
                                                              .substring(
                                                                0,
                                                                20,
                                                              ) +
                                                          ' ... ',
                                                  style: TextStyle(
                                                    color: Colora.scaffold,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Divider(color: Colora.scaffold),
                                              Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            Dimensions.width *
                                                            0.3,
                                                        child: Text(
                                                          inquiry['technical_detail']
                                                                      .length <
                                                                  20
                                                              ? inquiry['technical_detail']
                                                              : inquiry['technical_detail']
                                                                      .substring(
                                                                        0,
                                                                        20,
                                                                      ) +
                                                                  ' ... ',
                                                          style: TextStyle(
                                                            color:
                                                                Colora.scaffold,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  Dimensions
                                                                      .width *
                                                                  0.02,
                                                              vertical:
                                                                  Dimensions
                                                                      .height *
                                                                  0.005,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colora
                                                                  .appBarForgroundColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: SizedBox(
                                                          width:
                                                              Dimensions.width *
                                                              0.2,
                                                          child: Text(
                                                            "     نوع  :  ${inquiry['type'] == 'good' ? 'کالا' : 'خدمت'}     ",
                                                            style: ATextStyle
                                                                .light12
                                                                .copyWith(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 1),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            Dimensions.width *
                                                            0.4,
                                                        child: Text(
                                                          'تاریخ : ${inquiry['expiry']}'
                                                                      .length <
                                                                  20
                                                              ? 'تاریخ : ${inquiry['expiry']}'
                                                              : '${'تاریخ : ${inquiry['expiry']}'.substring(0, 20)} ... ',
                                                          style: TextStyle(
                                                            color:
                                                                Colora.scaffold,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'شناسه : ${inquiry['user']['id']}',
                                                        style: TextStyle(
                                                          color:
                                                              Colora.scaffold,
                                                        ),
                                                      ),
                                                      SizedBox(width: 1),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                //buttons
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return SizeTransition(
                                      sizeFactor: animation,
                                      child: child,
                                    );
                                  },
                                  child:
                                      visibleInquiriesButtons.contains(inquiry)
                                          ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                //preview
                                                CustomButton(
                                                  width: 110,
                                                  onPress: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) {
                                                          return SubmitFeeInquiryScreen(
                                                            isEdit: true,
                                                            id: inquiry['id'],
                                                          );
                                                        },
                                                      ),
                                                    ).whenComplete(() {
                                                      setState(() {
                                                        getInquiries();
                                                      });
                                                    });
                                                  },
                                                  text: 'ویرایش / نمایش',
                                                ),

                                                //edit
                                                CustomButton(
                                                  width: 110,
                                                  onPress: () {
                                                    dialog(inquiry['id']);
                                                  },
                                                  text: 'ارسال استعلام',
                                                ),

                                                //share
                                                CustomButton(
                                                  width: 110,
                                                  onPress: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) {
                                                          return InquiryDashboard();
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  text: 'داشبورد',
                                                ),
                                              ],
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return SubmitFeeInquiryScreen(
                                isEdit: false,
                                id: '',
                              );
                            },
                          ),
                        ).whenComplete(() {
                          setState(() {
                            getInquiries();
                          });
                        });
                        /*  Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubmitFeeInquiryScreen(),
                          ),
                        ); */
                      },
                      text: "درخواست جدید",
                      width: 200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const SimpleBotNavBar(),
    );
  }
}

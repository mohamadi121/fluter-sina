import 'dart:io';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/helper/snack_bar_util.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/widgets/appbar/default_appbar.dart';
import 'package:asood/core/widgets/custom_button.dart';
import 'package:asood/core/widgets/custom_textfield.dart';
import 'package:asood/core/widgets/radio_button.dart';
import 'package:asood/features/inquiry/data/data_source/inquiry_api_service.dart';
import 'package:asood/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SubmitFeeInquiryScreen extends StatefulWidget {
  final bool isEdit;
  final String id;
  const SubmitFeeInquiryScreen({
    super.key,
    required this.isEdit,
    required this.id,
  });

  @override
  State<SubmitFeeInquiryScreen> createState() => _SubmitFeeInquiryScreenState();
}

class _SubmitFeeInquiryScreenState extends State<SubmitFeeInquiryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String type = 'good';
  String name = '';
  String description = '';
  String technicalDetails = '';
  String amount = '';
  String unit = '';
  String expiry = '';
  XFile image = XFile('');
  String lastImage = '';
  int date = 0;
  String send = '';

  var imageFile;

  final InquiryAPIService _api = locator<InquiryAPIService>();

  void getLastData() async {
    final res = await _api.detail(widget.id);
    if (!mounted || res is! Success || res.response is! Map) {
      return;
    }
    final data = Map<String, dynamic>.from(res.response as Map);

    setState(() {
      type = data['type']?.toString() ?? 'good';
      name = data['name']?.toString() ?? '';
      technicalDetails = data['technical_detail']?.toString() ?? '';
      amount = data['amount']?.toString() ?? '';
      unit = data['unit']?.toString() ?? '';
      expiry = data['expiry'].toString();
      final images = data['images'];
      lastImage =
          images is List && images.isNotEmpty
              ? 'https://asoud.ir${images[0]['image']}'
              : '';
      send = data['send']?.toString() ?? '';
    });
  }

  void putChanges() async {
    final res = await _api.update(widget.id, {
      "type": type.toString(),
      "name": name,
      "technical_detail": description,
      "amount": amount == "" ? "0" : amount,
      "unit": unit == "" ? "0" : unit,
    });
    if (!mounted) {
      return;
    }
    if (res is Success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('استعلام با موفقیت ویرایش شد'),
        ),
      );
    } else {
      showSnackBar(
        context,
        res is Failure ? res.message : 'ویرایش استعلام ناموفق بود',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.isEdit) {
      getLastData();
    }
    super.initState();
  }

  void sendImageAndChat(id, image) {
    void sendData(String send) async {
      // Upload the image (if any), then finalize/send the inquiry.
      if (image != null && image is XFile && image.path.isNotEmpty) {
        await _api.uploadImage(id.toString(), image);
      }
      final res = await _api.send(id.toString());
      if (!mounted) {
        return;
      }
      if (res is Success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('استعلام جدید با موفقیت ایجاد شد'),
          ),
        );
      } else {
        showSnackBar(
          context,
          res is Failure ? res.message : 'ارسال استعلام ناموفق بود',
        );
      }
    }

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
                          sendData('sms');
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
                          sendData('chat');
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

    // Navigator.pop(context);
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         backgroundColor: Colors.green,
    //         content: Text('استعلام جدید با موفقیت ایجاد شد'),
    //       ),
    //     );
  }

  void sendInquiry(
    String type,
    String name,
    String description,
    String send,
    // File? image,
    String amount,
    String unit,
    int date,
  ) async {
    String type_ = type == 'good' ? 'محصول' : 'خدمت';

    if (name == '') {
      showSnackBar(context, 'لطفاً نام $type_ را وارد کنید');
    } else if (description == '') {
      showSnackBar(context, 'لطفاً توضیحات $type_ را وارد کنید');
    } else if (send == 'نحوه استعلام') {
      showSnackBar(context, 'لطفاً نحوه استعلام را وارد کنید');
    } else {
      DateTime now = DateTime.now();

      final res = await _api.create({
        "type": type.toString(),
        "name": name,
        "technical_detail": description,
        "expiry": DateTime(now.year, now.month, now.day + date).toString(),
        "amount": amount == "" ? "0" : amount,
        "unit": unit == "" ? "0" : unit,
      });
      if (!mounted) {
        return;
      }
      if (res is Success && res.response is Map) {
        final id = (res.response as Map)['id'];
        sendImageAndChat(id, image);
      } else {
        showSnackBar(
          context,
          res is Failure ? res.message : 'ایجاد استعلام ناموفق بود',
        );
      }
    }

    //   void sendReply(parrentId, message) async {
    //   String url = 'http://asoud.ir/api/v1/user/comment/create/';

    //   String? token = await SecureStorage.readSecureStorage(Keys.token);

    //   Map<String, String> data_ = {
    //     "content_type": "product",
    //     "object_id": widget.productDetails.id.toString(),
    //     "parent_id": parrentId.toString(),
    //     "comment": message.toString(),
    //   };

    //   var data = json.encode(data_);

    //   if (response.statusCode == 201) {
    //     setState(() {
    //       getProductByID(widget.productDetails.id.toString());
    //       getCommentsByID(widget.productDetails.id.toString());
    //       getDiscountByID(widget.productDetails.id.toString());
    //       nameController.clear();
    //       emailController.clear();
    //       messageController.clear();

    //       replyId = -1;
    //     });
    //   } else {}
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(
        title: widget.isEdit ? 'ویرایش استعلام' : 'افزودن استعلام جدید',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              width: Dimensions.width * 0.9,
              margin: const EdgeInsets.all(20),
              child: Column(children: [_buildRadioButtons(), _buildForm()]),
            ),
          ),
        ),
      ),
      extendBody: true,
      // bottomNavigationBar: SimpleBotNavBar(),
    );
  }

  Widget _buildRadioButtons() {
    return IntrinsicWidth(
      child: Container(
        height: 80,
        // width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colora.primaryColor,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              radioButton(
                title: 'محصول',
                groupValue: 'good',
                value: type,
                onChanged: (value) {
                  setState(() {
                    type = 'good';
                  });
                },
              ),
              radioButton(
                title: 'خدمت',
                groupValue: 'service',
                value: type,
                onChanged: (value) {
                  setState(() {
                    type = 'service';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: Dimensions.width * 0.9,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colora.primaryColor,
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _titleController,

            text: widget.isEdit ? name : "نام کالای مورد نیاز",
            onChanged: (p0) => name = p0,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _descriptionController,
            text: widget.isEdit ? technicalDetails : "توضیحات",
            maxLine: 5,
            onChanged: (p1) => description = p1,
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colora.backgroundSwitch,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    controller: _amountController,
                    text: widget.isEdit ? amount : "مقدار",
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9۰-۹]')),
                    ],
                    onChanged: (p0) {
                      amount = p0;
                    },
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    controller: _unitController,
                    text: widget.isEdit ? unit : "واحد",
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9۰-۹]')),
                    ],
                    onChanged: (p0) {
                      unit = p0;
                    },
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    controller: _dateController,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9۰-۹]')),
                    ],
                    text: 'به مدت',
                    onChanged: (p0) {
                      date = int.parse(p0);
                      setState(() {
                        _dateController.text = '$p0 روز';
                        if (p0 == '') {
                          _dateController.clear();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text("تصویر کالا"),
                const Text(
                  "عکس مورد نظر خود را از این بخش میتوانید بارگزاری نمایید:",
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10.0),
                      width: 50,
                      child: CustomButton(
                        onPress: () async {
                          var maxFileSizeInBytes = 5 * 1048576;

                          final ImagePicker picker = ImagePicker();
                          XFile? logoImage = await picker.pickImage(
                            source: ImageSource.gallery,
                          );

                          setState(() {
                            imageFile = logoImage!;
                          });

                          var imagePath = await logoImage!.readAsBytes();
                          setState(() {
                            image = imageFile;
                          });
                          var fileSize = imagePath.length;
                          if (context.mounted) {
                            if (fileSize <= maxFileSizeInBytes) {
                              // context.read<AddProductBloc>().add(
                              //   UpdateCategoryImageEvent(
                              //     selectedCategoryImage: logoImage.path,
                              //     selectedCategoryImageFile: logoImage,
                              //   ),
                              // );
                            } else {
                              showSnackBar(
                                context,
                                "حجم عکس بیش از ۵ مگابایت است",
                              );
                            }
                          }
                        },
                        text: imageFile == null ? "افزودن" : 'ویرایش',
                      ),
                    ),
                    widget.isEdit
                        ? lastImage == ''
                            ? Container()
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                lastImage,
                                height: Dimensions.height * 0.1,
                                width: Dimensions.height * 0.1,
                                fit: BoxFit.fill,
                              ),
                            )
                        : imageFile != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.file(
                            File(imageFile.path),
                            height: Dimensions.height * 0.1,
                            width: Dimensions.height * 0.1,
                            fit: BoxFit.fill,
                          ),
                        )
                        : Container(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 150,
                margin: const EdgeInsets.all(10.0),
                child: CustomButton(
                  onPress: () {
                    if (widget.isEdit) {
                      putChanges();
                    } else {
                      sendInquiry(
                        type,
                        name,
                        description,
                        'sms',
                        // File(imageFile.path),
                        amount,
                        unit,
                        date,
                      );
                    }
                  },
                  text: "ثبت",
                  color: Colors.white,
                  textColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

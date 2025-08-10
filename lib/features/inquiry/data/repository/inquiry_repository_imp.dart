import 'dart:io';

import 'package:asoud/features/inquiry/data/data_source/inquiry_api_service.dart';
import 'package:asoud/features/inquiry/domain/inquiry_repository.dart';

class InquiryRepoImp implements InquiryRepo {
  InquiryAPIService inquiryAPIService;
  InquiryRepoImp({required this.inquiryAPIService});
  @override
  Future submitInquiry(
    String inquiryType,
    String inquiryTitle,
    String? inquiryDescription,
    String? inquiryDetails,
    String inquiryCategory,
    double? inquiryAmount,
    String? inquiryUnit,
    String? inquiryName,
    List<File>? inquiryImages,
  ) async {
    var res = await inquiryAPIService.submitInquiry(
      inquiryType,
      inquiryTitle,
      inquiryDescription,
      inquiryDetails,
      inquiryCategory,
      inquiryAmount,
      inquiryUnit,
      inquiryName,
      inquiryImages,
    );
    return res;
  }
}

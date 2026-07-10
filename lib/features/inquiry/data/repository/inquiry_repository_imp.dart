import 'package:image_picker/image_picker.dart';

import 'package:asood/features/inquiry/data/data_source/inquiry_api_service.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';

class InquiryRepoImp implements InquiryRepo {
  final InquiryAPIService inquiryAPIService;
  InquiryRepoImp({required this.inquiryAPIService});

  @override
  Future list() => inquiryAPIService.list();

  @override
  Future detail(String id) => inquiryAPIService.detail(id);

  @override
  Future answers(String id) => inquiryAPIService.answers(id);

  @override
  Future createInquiry(Map<String, dynamic> body) =>
      inquiryAPIService.create(body);

  @override
  Future uploadImage(String id, XFile image) =>
      inquiryAPIService.uploadImage(id, image);

  @override
  Future sendInquiry(String id) => inquiryAPIService.send(id);

  @override
  Future deleteInquiry(String id) => inquiryAPIService.delete(id);
}

import 'package:image_picker/image_picker.dart';

abstract class InquiryRepo {
  Future<dynamic> list();
  Future<dynamic> detail(String id);
  Future<dynamic> answers(String id);
  Future<dynamic> createInquiry(Map<String, dynamic> body);
  Future<dynamic> uploadImage(String id, XFile image);
  Future<dynamic> sendInquiry(String id);
  Future<dynamic> deleteInquiry(String id);
}

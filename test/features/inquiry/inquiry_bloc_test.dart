import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';
import 'package:asood/features/inquiry/presentation/blocs/inquiry_bloc.dart';

class _FakeInquiryRepo implements InquiryRepo {
  dynamic createRes;
  dynamic uploadRes;
  dynamic sendRes;
  Map<String, dynamic>? lastCreateBody;
  final uploads = <String>[];
  final sent = <String>[];

  @override
  Future createInquiry(Map<String, dynamic> body) async {
    lastCreateBody = body;
    return createRes;
  }

  @override
  Future uploadImage(String id, XFile image) async {
    uploads.add(id);
    return uploadRes;
  }

  @override
  Future sendInquiry(String id) async {
    sent.add(id);
    return sendRes;
  }

  @override
  Future list() async => throw UnimplementedError();
  @override
  Future detail(String id) async => throw UnimplementedError();
  @override
  Future answers(String id) async => throw UnimplementedError();
  @override
  Future deleteInquiry(String id) async => throw UnimplementedError();
}

void main() {
  late _FakeInquiryRepo repo;
  late InquiryBloc bloc;

  setUp(() {
    repo = _FakeInquiryRepo();
    bloc = InquiryBloc(repo);
  });

  tearDown(() => bloc.close());

  test('submit creates, uploads each image, then sends', () async {
    repo.createRes = Success(code: 201, response: {'id': 'inq-1'});
    repo.uploadRes = Success(code: 200, response: {});
    repo.sendRes = Success(code: 200, response: {});

    bloc.add(
      InquirySubmit(
        inquiryType: 'good',
        inquiryTitle: 'title',
        inquiryCategory: 'c',
        inquiryDetails: 'detail',
        inquiryImages: [File('a.jpg'), File('b.jpg')],
      ),
    );
    await bloc.stream.firstWhere((s) => s.status == CWSStatus.success);

    expect(repo.lastCreateBody!['name'], 'title');
    expect(repo.lastCreateBody!['technical_detail'], 'detail');
    expect(repo.uploads, ['inq-1', 'inq-1']); // both images
    expect(repo.sent, ['inq-1']);
  });

  test('create failure ends in failure without upload/send', () async {
    repo.createRes = Failure(
      code: 400,
      errorResponse: 'bad',
      kind: FailureKind.validation,
    );

    bloc.add(
      const InquirySubmit(
        inquiryType: 'good',
        inquiryTitle: 't',
        inquiryCategory: 'c',
      ),
    );
    await bloc.stream.firstWhere((s) => s.status == CWSStatus.failure);

    expect(repo.uploads, isEmpty);
    expect(repo.sent, isEmpty);
  });

  test('missing id in create response is a failure', () async {
    repo.createRes = Success(code: 201, response: {'no_id': true});

    bloc.add(
      const InquirySubmit(
        inquiryType: 'good',
        inquiryTitle: 't',
        inquiryCategory: 'c',
      ),
    );
    await bloc.stream.firstWhere((s) => s.status == CWSStatus.failure);

    expect(repo.sent, isEmpty);
  });
}

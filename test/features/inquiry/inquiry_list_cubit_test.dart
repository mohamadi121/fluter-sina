import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';
import 'package:asood/features/inquiry/presentation/blocs/inquiry_list_cubit.dart';

class _FakeInquiryRepo implements InquiryRepo {
  dynamic listRes;
  dynamic sendRes;
  dynamic deleteRes;
  final sent = <String>[];
  final deleted = <String>[];

  @override
  Future list() async => listRes;

  @override
  Future sendInquiry(String id) async {
    sent.add(id);
    return sendRes;
  }

  @override
  Future deleteInquiry(String id) async {
    deleted.add(id);
    return deleteRes;
  }

  @override
  Future detail(String id) async => throw UnimplementedError();
  @override
  Future answers(String id) async => throw UnimplementedError();
  @override
  Future createInquiry(Map<String, dynamic> body) async =>
      throw UnimplementedError();
  @override
  Future uploadImage(String id, XFile image) async =>
      throw UnimplementedError();
}

void main() {
  late _FakeInquiryRepo repo;
  late InquiryListCubit cubit;

  setUp(() {
    repo = _FakeInquiryRepo();
    cubit = InquiryListCubit(repo: repo);
  });

  tearDown(() => cubit.close());

  test('load maps the inquiry list', () async {
    repo.listRes = Success(
      code: 200,
      response: [
        {'id': 'i1', 'name': 'estelam'},
      ],
    );

    await cubit.load();

    expect(cubit.state.status, InquiryListStatus.loaded);
    expect(cubit.state.inquiries.single['name'], 'estelam');
  });

  test('load failure surfaces backend detail', () async {
    repo.listRes = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    await cubit.load();

    expect(cubit.state.status, InquiryListStatus.failure);
    expect(cubit.state.error, 'boom');
  });

  test('send returns true on success', () async {
    repo.sendRes = Success(code: 200, message: 'sent');

    final ok = await cubit.send('i1');

    expect(ok, isTrue);
    expect(repo.sent, ['i1']);
  });

  test('delete removes the row locally on success', () async {
    repo.listRes = Success(
      code: 200,
      response: [
        {'id': 'i1'},
        {'id': 'i2'},
      ],
    );
    await cubit.load();
    repo.deleteRes = Success(code: 200, message: 'deleted');

    await cubit.delete('i1');

    expect(cubit.state.inquiries.single['id'], 'i2');
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/bank_card/bloc/bank_info_cubit.dart';
import 'package:asood/features/bank_card/data/bank_api_service.dart';

class _FakeBankApi implements BankApiService {
  dynamic banksResult;
  dynamic listResult;
  dynamic createResult;
  dynamic updateResult;
  dynamic deleteResult;
  Map<String, dynamic>? savedBody;
  String? updatedId;
  String? deletedId;

  @override
  Future banks() async => banksResult;

  @override
  Future myBankInfos() async => listResult;

  @override
  Future create(Map<String, dynamic> body) async {
    savedBody = body;
    return createResult;
  }

  @override
  Future update(String id, Map<String, dynamic> body) async {
    updatedId = id;
    savedBody = body;
    return updateResult;
  }

  @override
  Future delete(String id) async {
    deletedId = id;
    return deleteResult;
  }

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeBankApi api;
  late BankInfoCubit cubit;

  setUp(() {
    api = _FakeBankApi();
    cubit = BankInfoCubit(api: api);
  });

  tearDown(() => cubit.close());

  Future<void> loadOne() async {
    api.banksResult = Success(
      code: 200,
      response: [
        {'id': 'b1', 'name': 'Mellat'},
      ],
    );
    api.listResult = Success(
      code: 200,
      response: [
        {'id': 'i1', 'bank_info_id': 'b1', 'full_name': 'Old'},
      ],
    );
    await cubit.load();
  }

  test('load maps bank catalog and authenticated bank infos', () async {
    await loadOne();

    expect(cubit.state.status, BankInfoStatus.loaded);
    expect(cubit.state.banks.single['name'], 'Mellat');
    expect(cubit.state.bankInfos.single['id'], 'i1');
  });

  test('load failure surfaces backend detail', () async {
    api.banksResult = Failure(
      code: 503,
      errorResponse: 'catalog unavailable',
      kind: FailureKind.server,
    );
    api.listResult = Success(code: 200, response: const []);

    await cubit.load();

    expect(cubit.state.status, BankInfoStatus.failure);
    expect(cubit.state.error, 'catalog unavailable');
  });

  test('create inserts the authoritative server response', () async {
    await loadOne();
    api.createResult = Success(
      code: 201,
      response: {'id': 'i2', 'bank_info_id': 'b1', 'full_name': 'New'},
    );

    final saved = await cubit.save(body: {'bank_info': 'b1'});

    expect(saved, isTrue);
    expect(api.savedBody, {'bank_info': 'b1'});
    expect(cubit.state.bankInfos.first['id'], 'i2');
  });

  test('update replaces the matching row with server data', () async {
    await loadOne();
    api.updateResult = Success(
      code: 200,
      response: {'id': 'i1', 'bank_info_id': 'b1', 'full_name': 'Updated'},
    );

    final saved = await cubit.save(id: 'i1', body: {'full_name': 'Updated'});

    expect(saved, isTrue);
    expect(api.updatedId, 'i1');
    expect(cubit.state.bankInfos.single['full_name'], 'Updated');
  });

  test('delete removes on success and keeps the row on failure', () async {
    await loadOne();
    api.deleteResult = Failure(
      code: 500,
      errorResponse: 'cannot delete',
      kind: FailureKind.server,
    );

    final failed = await cubit.delete('i1');

    expect(failed, isFalse);
    expect(cubit.state.bankInfos, hasLength(1));
    expect(cubit.state.error, 'cannot delete');

    api.deleteResult = Success(code: 204);
    final deleted = await cubit.delete('i1');

    expect(deleted, isTrue);
    expect(api.deletedId, 'i1');
    expect(cubit.state.bankInfos, isEmpty);
    expect(cubit.state.pendingIds, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/profile/bloc/profile_cubit.dart';
import 'package:asood/features/profile/data/profile_api_service.dart';

class _FakeProfileApi implements ProfileApiService {
  dynamic getResult;
  dynamic updateResult;
  Map<String, dynamic>? updatedBody;

  @override
  Future getProfile() async => getResult;

  @override
  Future updateProfile(Map<String, dynamic> body) async {
    updatedBody = body;
    return updateResult;
  }

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeProfileApi api;
  late ProfileCubit cubit;

  setUp(() {
    api = _FakeProfileApi();
    cubit = ProfileCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps authenticated profile envelope data', () async {
    api.getResult = Success(
      code: 200,
      response: {
        'id': 1,
        'mobile_number': '09120000000',
        'profile': {'national_code': '1234567890'},
      },
    );

    await cubit.load();

    expect(cubit.state.status, ProfileStatus.loaded);
    expect(cubit.state.data['mobile_number'], '09120000000');
  });

  test(
    'save sends editable fields and accepts server-owned identity',
    () async {
      api.updateResult = Success(
        code: 200,
        response: {
          'id': 1,
          'mobile_number': '09120000000',
          'profile': {'address': 'Tehran', 'national_code': '1234567890'},
        },
      );

      final saved = await cubit.save({
        'address': 'Tehran',
        'national_code': '1234567890',
      });

      expect(saved, isTrue);
      expect(api.updatedBody!['address'], 'Tehran');
      expect(cubit.state.data['mobile_number'], '09120000000');
    },
  );

  test('save failure surfaces backend validation detail', () async {
    api.updateResult = Failure(
      code: 400,
      errorResponse: 'National code must contain 10 digits.',
      kind: FailureKind.validation,
    );

    final saved = await cubit.save({'national_code': '123'});

    expect(saved, isFalse);
    expect(cubit.state.status, ProfileStatus.failure);
    expect(cubit.state.error, 'National code must contain 10 digits.');
  });
}

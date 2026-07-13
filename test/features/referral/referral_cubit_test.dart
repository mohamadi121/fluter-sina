import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/referral/bloc/referral_cubit.dart';
import 'package:asood/features/referral/data/referral_api_service.dart';

class _FakeReferralApi implements ReferralApiService {
  dynamic summaryResult;
  dynamic applyResult;
  String? appliedCode;

  @override
  Future summary() async => summaryResult;

  @override
  Future applyCode(String code) async {
    appliedCode = code;
    return applyResult;
  }

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeReferralApi api;
  late ReferralCubit cubit;

  setUp(() {
    api = _FakeReferralApi();
    cubit = ReferralCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps referral count and privacy-safe ids', () async {
    api.summaryResult = Success(
      code: 200,
      response: {
        'id': 1,
        'referral_count': 2,
        'referrees': [
          {'id': 2},
          {'id': 3},
        ],
      },
    );

    await cubit.load();

    expect(cubit.state.status, ReferralStatus.loaded);
    expect(cubit.state.referralCount, 2);
    expect(cubit.state.referredUserIds, ['2', '3']);
  });

  test('apply trims code and reloads summary', () async {
    api.applyResult = Success(code: 201, response: {'id': 'r1'});
    api.summaryResult = Success(
      code: 200,
      response: {'referral_count': 0, 'referrees': []},
    );

    final applied = await cubit.applyCode(' 09121234567 ');

    expect(applied, isTrue);
    expect(api.appliedCode, '09121234567');
    expect(cubit.state.status, ReferralStatus.loaded);
  });

  test('empty code fails locally without a request', () async {
    final applied = await cubit.applyCode('   ');

    expect(applied, isFalse);
    expect(api.appliedCode, isNull);
    expect(cubit.state.status, ReferralStatus.failure);
  });

  test('backend conflict surfaces its typed error', () async {
    api.applyResult = Failure(
      code: 409,
      errorResponse: 'A different referral code was already applied.',
      kind: FailureKind.validation,
    );

    final applied = await cubit.applyCode('09121234567');

    expect(applied, isFalse);
    expect(cubit.state.error, 'A different referral code was already applied.');
  });
}

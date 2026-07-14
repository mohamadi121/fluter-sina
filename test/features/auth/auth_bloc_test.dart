import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';
import 'package:asood/features/auth/presentation/blocs/auth_bloc.dart';

import '../../core/auth/in_memory_token_storage.dart';

class _FakeAuthRepository implements AuthRepository {
  dynamic sendCodeResult;
  dynamic verifyCodeResult;
  dynamic logoutResult;
  bool logoutCalled = false;

  @override
  Future<dynamic> sendCode(String number) async => sendCodeResult;

  @override
  Future<dynamic> verifyCode(String number, String code) async =>
      verifyCodeResult;

  @override
  Future<dynamic> logout() async {
    logoutCalled = true;
    return logoutResult;
  }
}

void main() {
  late _FakeAuthRepository repository;
  late AuthSession session;
  late AuthBloc bloc;

  setUp(() async {
    repository = _FakeAuthRepository();
    session = AuthSession(InMemoryTokenStorage());
    await session.hydrate();
    bloc = AuthBloc(authRepository: repository, authSession: session);
  });

  tearDown(() => bloc.close());

  test('SendOtp success goes sendingOtp -> otpSent and keeps phone', () async {
    repository.sendCodeResult = Success(code: 200, message: 'sent');

    bloc.add(const SendOtp(phone: '09120000000'));

    await expectLater(
      bloc.stream.map((s) => s.status),
      emitsInOrder([AuthStatus.sendingOtp, AuthStatus.otpSent]),
    );
    expect(bloc.state.phoneNumber, '09120000000');
  });

  test('SendOtp failure surfaces backend detail', () async {
    repository.sendCodeResult = Failure(
      code: 429,
      errorResponse: 'Too many requests',
      kind: FailureKind.validation,
    );

    bloc.add(const SendOtp(phone: '09120000000'));

    await expectLater(
      bloc.stream.map((s) => s.status),
      emitsInOrder([AuthStatus.sendingOtp, AuthStatus.error]),
    );
    expect(bloc.state.error, 'Too many requests');
  });

  test('VerifyOtp success stores token in session and authenticates', () async {
    repository.verifyCodeResult = Success(
      code: 200,
      response: {'token': 'drf-token-key'},
    );

    bloc.add(const VerifyOtp(phone: '09120000000', otp: '1234'));

    await expectLater(
      bloc.stream.map((s) => s.status),
      emitsInOrder([AuthStatus.verifying, AuthStatus.authenticated]),
    );
    expect(session.token, 'drf-token-key');
  });

  test(
    'VerifyOtp with missing token in response errors without auth',
    () async {
      repository.verifyCodeResult = Success(code: 200, response: {});

      bloc.add(const VerifyOtp(phone: '09120000000', otp: '1234'));

      await expectLater(
        bloc.stream.map((s) => s.status),
        emitsInOrder([AuthStatus.verifying, AuthStatus.error]),
      );
      expect(session.isAuthenticated, isFalse);
    },
  );

  test('VerifyOtp wrong pin surfaces backend error', () async {
    repository.verifyCodeResult = Failure(
      code: 401,
      errorResponse: 'Pin not valid',
      kind: FailureKind.unauthorized,
    );

    bloc.add(const VerifyOtp(phone: '09120000000', otp: '9999'));

    await expectLater(
      bloc.stream.map((s) => s.status),
      emitsInOrder([AuthStatus.verifying, AuthStatus.error]),
    );
    expect(bloc.state.error, 'Pin not valid');
  });

  test('Logout clears session and resets state', () async {
    await session.setToken('tok');
    repository.logoutResult = Success(code: 204);

    bloc.add(Logout());

    await expectLater(
      bloc.stream.map((s) => s.status),
      emits(AuthStatus.initial),
    );
    expect(session.isAuthenticated, isFalse);
    expect(repository.logoutCalled, isTrue);
  });
}

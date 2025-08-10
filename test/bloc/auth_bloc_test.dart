import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asoud/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asoud/features/auth/domain/repository/auth_repository.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/network/app_error.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late AuthRepository mockRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be correct', () {
      expect(authBloc.state.status, isA<UiIdle>());
      expect(authBloc.state.phoneNumber, isEmpty);
      expect(authBloc.state.termStatus, isFalse);
      expect(authBloc.state.error, isEmpty);
    });

    group('SendOtp', () {
      const phoneNumber = '09123456789';

      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when send OTP succeeds',
        build: () {
          when(() => mockRepository.userAuth(phoneNumber))
              .thenAnswer((_) async => const Success(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SendOtp(phoneNumber)),
        expect: () => [
          AuthState(
            phoneNumber: phoneNumber,
            status: const UiLoading(),
            termStatus: false,
            error: '',
          ),
          AuthState(
            phoneNumber: phoneNumber,
            status: const UiSuccess(),
            termStatus: false,
            error: '',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.userAuth(phoneNumber)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when send OTP fails',
        build: () {
          when(() => mockRepository.userAuth(phoneNumber))
              .thenAnswer((_) async => Failure(BusinessError(message: 'خطا در ارسال کد')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const SendOtp(phoneNumber)),
        expect: () => [
          AuthState(
            phoneNumber: phoneNumber,
            status: const UiLoading(),
            termStatus: false,
            error: '',
          ),
          AuthState(
            phoneNumber: phoneNumber,
            status: const UiError('خطا در ارسال کد'),
            termStatus: false,
            error: 'خطا در ارسال کد',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.userAuth(phoneNumber)).called(1);
        },
      );
    });

    group('VerifyOtp', () {
      const phoneNumber = '09123456789';
      const otpCode = '12345';
      const token = 'auth_token_123';

      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when verify OTP succeeds',
        build: () {
          when(() => mockRepository.verifyUser(phoneNumber, otpCode))
              .thenAnswer((_) async => const Success(token));
          return authBloc;
        },
        act: (bloc) => bloc.add(const VerifyOtp(phoneNumber, otpCode)),
        expect: () => [
          const AuthState(
            phoneNumber: '',
            status: UiLoading(),
            termStatus: false,
            error: '',
          ),
          const AuthState(
            phoneNumber: '',
            status: UiSuccess(),
            termStatus: false,
            error: '',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.verifyUser(phoneNumber, otpCode)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when verify OTP fails',
        build: () {
          when(() => mockRepository.verifyUser(phoneNumber, otpCode))
              .thenAnswer((_) async => Failure(BusinessError(message: 'کد تایید نامعتبر')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const VerifyOtp(phoneNumber, otpCode)),
        expect: () => [
          const AuthState(
            phoneNumber: '',
            status: UiLoading(),
            termStatus: false,
            error: '',
          ),
          const AuthState(
            phoneNumber: '',
            status: UiError('کد تایید نامعتبر'),
            termStatus: false,
            error: 'کد تایید نامعتبر',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.verifyUser(phoneNumber, otpCode)).called(1);
        },
      );
    });

    group('ToggleTermsCheckboxEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits state with updated termStatus when toggled',
        build: () => authBloc,
        act: (bloc) => bloc.add(const ToggleTermsCheckboxEvent(true)),
        expect: () => [
          const AuthState(
            phoneNumber: '',
            status: UiIdle(),
            termStatus: true,
            error: '',
          ),
        ],
      );
    });

    group('Logout', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when logout succeeds',
        build: () {
          when(() => mockRepository.logoutUser())
              .thenAnswer((_) async => const Success(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const Logout()),
        expect: () => [
          const AuthState(
            phoneNumber: '',
            status: UiLoading(),
            termStatus: false,
            error: '',
          ),
          const AuthState(
            phoneNumber: '',
            status: UiSuccess(),
            termStatus: false,
            error: '',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.logoutUser()).called(1);
        },
      );
    });
  });
}

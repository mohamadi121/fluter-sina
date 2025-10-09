import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';

import 'package:asood/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';
import 'package:asood/core/http_client/api_status.dart';

import '../mocks/mock_dependencies.dart';

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be correct', () {
      expect(authBloc.state, equals(AuthState.initial()));
    });

    group('SendOtp', () {
      const String testPhoneNumber = '09123456789';

      blocTest<AuthBloc, AuthState>(
        'emits loading then success when sendCode succeeds',
        build: () {
          when(mockAuthRepository.sendCode(testPhoneNumber))
              .thenAnswer((_) async => Success(code: 200, response: {}));
          return authBloc;
        },
        act: (bloc) => bloc.add(SendOtp(phone: testPhoneNumber)),
        expect: () => [
          authBloc.state.copyWith(
            status: AuthStatus.loading,
            phoneNumber: testPhoneNumber,
          ),
          authBloc.state.copyWith(
            status: AuthStatus.success,
            phoneNumber: testPhoneNumber,
          ),
        ],
        verify: (_) {
          verify(mockAuthRepository.sendCode(testPhoneNumber)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits loading then error when sendCode fails',
        build: () {
          when(mockAuthRepository.sendCode(testPhoneNumber))
              .thenAnswer((_) async => Failure(
                  code: 400, errorResponse: 'Invalid phone number'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SendOtp(phone: testPhoneNumber)),
        expect: () => [
          authBloc.state.copyWith(
            status: AuthStatus.loading,
            phoneNumber: testPhoneNumber,
          ),
          authBloc.state.copyWith(
            status: AuthStatus.error,
            phoneNumber: testPhoneNumber,
            error: 'Invalid phone number',
          ),
        ],
      );
    });

    group('VerifyOtp', () {
      const String testPhoneNumber = '09123456789';
      const String testOtp = '1234';
      const String testToken = 'test_token_123';

      blocTest<AuthBloc, AuthState>(
        'emits loading then success when verifyCode succeeds',
        build: () {
          when(mockAuthRepository.verifyCode(testPhoneNumber, testOtp))
              .thenAnswer((_) async => Success(
                    code: 200,
                    response: {'token': testToken},
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(VerifyOtp(phone: testPhoneNumber, otp: testOtp)),
        expect: () => [
          authBloc.state.copyWith(status: AuthStatus.loading),
          authBloc.state.copyWith(status: AuthStatus.success),
        ],
        verify: (_) {
          verify(mockAuthRepository.verifyCode(testPhoneNumber, testOtp))
              .called(1);
        },
      );
    });

    group('ToggleTermsCheckbox', () {
      blocTest<AuthBloc, AuthState>(
        'updates termStatus when checkbox is toggled',
        build: () => authBloc,
        act: (bloc) => bloc.add(ToggleTermsCheckboxEvent(isClicked: true)),
        expect: () => [
          authBloc.state.copyWith(termStatus: true),
        ],
      );
    });
  });
}
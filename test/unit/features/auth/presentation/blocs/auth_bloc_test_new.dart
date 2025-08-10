import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asoud/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asoud/features/auth/data/repository/auth_repository_migrated.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/network/app_error.dart';

class MockAuthRepositoryMigrated extends Mock implements AuthRepositoryMigrated {}

void main() {
  group('AuthBloc', () {
    late AuthRepositoryMigrated mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepositoryMigrated();
    });

    group('constructor', () {
      test('initial state is correct', () {
        final authBloc = AuthBloc(authRepository: mockAuthRepository);
        
        expect(authBloc.state.status, isA<UiIdle>());
        expect(authBloc.state.phoneNumber, isEmpty);
        expect(authBloc.state.termStatus, isFalse);
        expect(authBloc.state.error, isEmpty);
      });
    });

    group('SendOtp', () {
      blocTest<AuthBloc, AuthState>(
        'emits loading then success when userAuth succeeds',
        build: () {
          when(() => mockAuthRepository.userAuth(any()))
              .thenAnswer((_) async => const Success<void>(null));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const SendOtp(phone: '09123456789')),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiLoading>())
              .having((s) => s.phoneNumber, 'phoneNumber', '09123456789'),
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiSuccess>())
              .having((s) => s.phoneNumber, 'phoneNumber', '09123456789'),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.userAuth('09123456789')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits loading then error when userAuth fails',
        build: () {
          when(() => mockAuthRepository.userAuth(any()))
              .thenAnswer((_) async => Failure<void>(BusinessError(message: 'Invalid phone')));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const SendOtp(phone: '0912')),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiLoading>())
              .having((s) => s.phoneNumber, 'phoneNumber', '0912'),
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiError>())
              .having((s) => s.error, 'error', 'Invalid phone'),
        ],
      );
    });

    group('VerifyOtp', () {
      blocTest<AuthBloc, AuthState>(
        'emits loading then success when verifyUser succeeds',
        build: () {
          when(() => mockAuthRepository.verifyUser(any(), any()))
              .thenAnswer((_) async => const Success<String>('fake_token'));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const VerifyOtp(phone: '09123456789', otp: '1234')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', isA<UiLoading>()),
          isA<AuthState>().having((s) => s.status, 'status', isA<UiSuccess>()),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.verifyUser('09123456789', '1234')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits loading then error when verifyUser fails',
        build: () {
          when(() => mockAuthRepository.verifyUser(any(), any()))
              .thenAnswer((_) async => Failure<String>(BusinessError(message: 'Invalid OTP')));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const VerifyOtp(phone: '09123456789', otp: '0000')),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', isA<UiLoading>()),
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiError>())
              .having((s) => s.error, 'error', 'Invalid OTP'),
        ],
      );
    });

    group('ToggleTermsCheckboxEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits state with updated termStatus',
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const ToggleTermsCheckboxEvent(isClicked: true)),
        expect: () => [
          isA<AuthState>().having((s) => s.termStatus, 'termStatus', isTrue),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits state with termStatus false',
        build: () => AuthBloc(authRepository: mockAuthRepository),
        act: (bloc) => bloc.add(const ToggleTermsCheckboxEvent(isClicked: false)),
        expect: () => [
          isA<AuthState>().having((s) => s.termStatus, 'termStatus', isFalse),
        ],
      );
    });

    group('Logout', () {
      blocTest<AuthBloc, AuthState>(
        'emits loading then success when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logoutUser())
              .thenAnswer((_) async => const Success<dynamic>(null));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(Logout()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', isA<UiLoading>()),
          isA<AuthState>().having((s) => s.status, 'status', isA<UiSuccess>()),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logoutUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits loading then error when logout fails',
        build: () {
          when(() => mockAuthRepository.logoutUser())
              .thenAnswer((_) async => Failure<dynamic>(UnknownError(message: 'Logout failed')));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(Logout()),
        expect: () => [
          isA<AuthState>().having((s) => s.status, 'status', isA<UiLoading>()),
          isA<AuthState>()
              .having((s) => s.status, 'status', isA<UiError>())
              .having((s) => s.error, 'error', 'Logout failed'),
        ],
      );
    });
  });
}

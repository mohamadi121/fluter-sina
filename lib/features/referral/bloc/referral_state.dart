part of 'referral_cubit.dart';

enum ReferralStatus { initial, loading, loaded, submitting, failure }

class ReferralState extends Equatable {
  final ReferralStatus status;
  final int referralCount;
  final List<String> referredUserIds;
  final String? error;

  const ReferralState({
    this.status = ReferralStatus.initial,
    this.referralCount = 0,
    this.referredUserIds = const [],
    this.error,
  });

  ReferralState copyWith({
    ReferralStatus? status,
    int? referralCount,
    List<String>? referredUserIds,
    String? error,
  }) {
    return ReferralState(
      status: status ?? this.status,
      referralCount: referralCount ?? this.referralCount,
      referredUserIds: referredUserIds ?? this.referredUserIds,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, referralCount, referredUserIds, error];
}

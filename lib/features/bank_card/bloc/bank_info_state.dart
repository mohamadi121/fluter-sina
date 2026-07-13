part of 'bank_info_cubit.dart';

enum BankInfoStatus { initial, loading, loaded, saving, failure }

class BankInfoState extends Equatable {
  final BankInfoStatus status;
  final List<Map<String, dynamic>> banks;
  final List<Map<String, dynamic>> bankInfos;
  final Set<String> pendingIds;
  final String? error;

  const BankInfoState({
    this.status = BankInfoStatus.initial,
    this.banks = const [],
    this.bankInfos = const [],
    this.pendingIds = const {},
    this.error,
  });

  BankInfoState copyWith({
    BankInfoStatus? status,
    List<Map<String, dynamic>>? banks,
    List<Map<String, dynamic>>? bankInfos,
    Set<String>? pendingIds,
    String? error,
  }) {
    return BankInfoState(
      status: status ?? this.status,
      banks: banks ?? this.banks,
      bankInfos: bankInfos ?? this.bankInfos,
      pendingIds: pendingIds ?? this.pendingIds,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, banks, bankInfos, pendingIds, error];
}

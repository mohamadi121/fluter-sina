part of 'inquiry_list_cubit.dart';

enum InquiryListStatus { initial, loading, loaded, failure }

class InquiryListState extends Equatable {
  final InquiryListStatus status;
  final List<Map<String, dynamic>> inquiries;
  final String? error;

  const InquiryListState({
    this.status = InquiryListStatus.initial,
    this.inquiries = const [],
    this.error,
  });

  InquiryListState copyWith({
    InquiryListStatus? status,
    List<Map<String, dynamic>>? inquiries,
    String? error,
  }) {
    return InquiryListState(
      status: status ?? this.status,
      inquiries: inquiries ?? this.inquiries,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, inquiries, error];
}

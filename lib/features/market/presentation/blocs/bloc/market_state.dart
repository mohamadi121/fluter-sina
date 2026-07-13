part of 'market_bloc.dart';

class MarketState {
  final CWSStatus status;
  final List<TemplateModel> templateList;
  final bool showTemplates;
  final int templateIndex;
  final String marketId;
  final String? feedback;

  const MarketState({
    required this.status,
    required this.templateList,
    required this.showTemplates,
    required this.templateIndex,
    required this.marketId,
    this.feedback,
  });

  factory MarketState.initial() {
    return const MarketState(
      status: CWSStatus.initial,
      templateList: [],
      showTemplates: false,
      templateIndex: 0,
      marketId: '',
      feedback: null,
    );
  }

  MarketState copyWith({
    CWSStatus? status,
    List<TemplateModel>? templateList,
    bool? showTemplates,
    int? templateIndex,
    String? marketId,
    String? feedback,
    bool clearFeedback = false,
  }) {
    return MarketState(
      status: status ?? this.status,
      templateList: templateList ?? this.templateList,
      showTemplates: showTemplates ?? this.showTemplates,
      templateIndex: templateIndex ?? this.templateIndex,
      marketId: marketId ?? this.marketId,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
    );
  }
}

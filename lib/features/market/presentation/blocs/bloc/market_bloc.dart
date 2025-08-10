import 'package:asoud/core/models/market_model.dart';
import 'package:asoud/features/market/data/model/market_model.dart';
import 'package:bloc/bloc.dart';
import 'package:asoud/features/market/domain/repository/product_repository.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/models/dto/product_dto.dart';
import 'package:asoud/core/ui/ui_status.dart';

part 'market_event.dart';
part 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final ProductRepository productRepository;
  MarketBloc({required this.productRepository}) : super(MarketState.initial()) {
    on<AddTemplateEvent>(_addTemplate);
    on<ChangeTemplateEvent>(_changeTemplate);
    on<LoadTemplateEvent>(_loadTemplate);
    on<RemoveTemplateEvent>(_removeTemplate);
    on<ShowTemplatesEvent>(_showTemplates);
  }

  Future<void> _addTemplate(AddTemplateEvent event, Emitter<MarketState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    final res = await productRepository.createMarketTheme(event.marketId, event.template);
    if (res is Success<bool>) {
      await _loadTemplate(LoadTemplateEvent(marketId: event.marketId), emit);
    } else {
      emit(state.copyWith(status: UiError(res.error.message)));
    }
    emit(state.copyWith(status: const UiIdle()));
  }

  Future<void> _loadTemplate(LoadTemplateEvent event, Emitter<MarketState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    final res = await productRepository.listMarketThemes(event.marketId);
    if (res is Success<List<ProductThemeDto>>) {
      final templateList = res.data.map((t) => TemplateModel.fromJson(t.toJson())).toList();
      emit(state.copyWith(status: const UiSuccess(), templateList: templateList, marketId: event.marketId, showTemplates: false));
    } else {
      emit(state.copyWith(status: UiError(res.error.message)));
    }
  }

  void _changeTemplate(ChangeTemplateEvent event, Emitter<MarketState> emit) {
    emit(state.copyWith(templateIndex: event.template));
  }

  void _removeTemplate(RemoveTemplateEvent event, Emitter<MarketState> emit) {
    state.templateList.removeAt(event.index);
    emit(state.copyWith(templateList: List.of(state.templateList)));
  }

  void _showTemplates(ShowTemplatesEvent event, Emitter<MarketState> emit) {
    emit(state.copyWith(showTemplates: event.isShow));
  }
}

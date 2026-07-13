import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/logging/app_logger.dart';
import 'package:asood/features/market/data/model/market_model.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:bloc/bloc.dart';

part 'market_event.dart';
part 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final ProductRepository productRepository;
  MarketBloc({required this.productRepository}) : super(MarketState.initial()) {
    on<AddTemplateEvent>(_addTemplate);
    on<ChangeTemplateEvent>(_changeTemplate);
    on<LoadTemplateEvent>(_loadTemplate);
    on<ShowTemplatesEvent>(_showTemplates);
  }

  _addTemplate(AddTemplateEvent event, Emitter<MarketState> emit) async {
    emit(state.copyWith(status: CWSStatus.loading, clearFeedback: true));
    try {
      final res = await productRepository.createMarketTheme(
        event.marketId,
        event.template,
      );

      if (res is Success) {
        await _loadTemplate(
          LoadTemplateEvent(marketId: event.marketId),
          emit,
          'قالب با موفقیت اضافه شد',
        );
        return;
      }
      emit(
        state.copyWith(
          status: CWSStatus.failure,
          feedback: res is Failure ? res.message : 'افزودن قالب ناموفق بود',
        ),
      );
    } catch (e, st) {
      AppLogger.error('market', 'addTemplate failed', e, st);
      emit(
        state.copyWith(
          status: CWSStatus.failure,
          feedback: 'افزودن قالب ناموفق بود',
        ),
      );
    }
  }

  _loadTemplate(
    LoadTemplateEvent event,
    Emitter<MarketState> emit, [
    String? successFeedback,
  ]) async {
    emit(state.copyWith(status: CWSStatus.loading, clearFeedback: true));
    try {
      final res = await productRepository.getMarketTheme(event.marketId);

      if (res is Success) {
        final initList = res.response as List<dynamic>;
        final templateList =
            initList.map((e) => TemplateModel.fromJson(e)).toList();
        emit(
          state.copyWith(
            status: CWSStatus.success,
            templateList: templateList,
            marketId: event.marketId,
            showTemplates: false,
            feedback: successFeedback,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: CWSStatus.failure,
            feedback:
                res is Failure ? res.message : 'دریافت قالب‌ها ناموفق بود',
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('market', 'loadTemplate failed', e, st);
      emit(
        state.copyWith(
          status: CWSStatus.failure,
          feedback: 'دریافت قالب‌ها ناموفق بود',
        ),
      );
    }
  }

  _changeTemplate(ChangeTemplateEvent event, Emitter<MarketState> emit) {
    emit(state.copyWith(templateIndex: event.template));
  }

  _showTemplates(ShowTemplatesEvent event, Emitter<MarketState> emit) {
    emit(state.copyWith(showTemplates: event.isShow));
  }
}

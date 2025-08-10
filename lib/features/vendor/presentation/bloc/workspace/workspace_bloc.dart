import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/models/market_model.dart';
import 'package:asoud/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:bloc/bloc.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final CreateMarketRepository marketRepo;

  WorkspaceBloc(this.marketRepo) : super(WorkspaceState.initial()) {
    on<LoadStores>(_getStores);
    on<ChangeTabView>(_changeActiveTab);
    on<ShowInvoice>(_changeInvoiceView);
    on<InvoiceOption>(_invoiceOptionView);
    on<InvoiceConfirm>(_invoiceConfirmView);
    on<SelectMarket>(_selectMarket);
    on<GetProducts>(_getProducts);
    on<ContactUs>(_contactUs);
    on<GetComments>(_getComments);
    on<GetSpecialProducts>(_getSpecialProducts);
    on<GetDiscounts>(_getDiscounts);
    on<DeleteDiscount>(_deleteDiscount);
    on<CreateDiscount>(_createDiscount);
    on<ChangeColorAndFont>(_changeColorAndFont);
    on<ChangeProductTheme>(_changeProductTheme);
    on<ChangeThemeColors>(_changeThemeColors);
    on<EditeWorkSpaceInfo>(_editeWorkSpaceInfo);
  }

  _changeActiveTab(ChangeTabView event, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(activeTabIndex: event.activeTabIndex));
  }

  _changeInvoiceView(ShowInvoice event, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(showInvoice: event.isShow));
  }

  _invoiceOptionView(InvoiceOption event, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(invoiceOption: event.option));
  }

  _invoiceConfirmView(InvoiceConfirm event, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(invoiceConfirm: event.isConfirm));
  }

  _getStores(LoadStores event, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = await marketRepo.getMarketList();
      if (res is Success) {
        final initList = res.data as List;
        final storesList = initList.map((e) => MarketModel.fromJson(e)).toList();
        emit(state.copyWith(status: const UiSuccess(), storesList: storesList));
      } else {
        emit(state.copyWith(status: UiError('دریافت فروشگاه‌ها ناموفق بود')));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  _selectMarket(SelectMarket event, Emitter<WorkspaceState> emit) {
    emit(state.copyWith(selectedMarket: event.marketId));
  }

  _genericLoadingSuccess(Function body, Emitter<WorkspaceState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      await body();
      emit(state.copyWith(status: const UiSuccess()));
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  _getProducts(GetProducts event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _contactUs(ContactUs event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _getComments(GetComments event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _getSpecialProducts(GetSpecialProducts event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _getDiscounts(GetDiscounts event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _deleteDiscount(DeleteDiscount event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _createDiscount(CreateDiscount event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _changeColorAndFont(ChangeColorAndFont event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _editeWorkSpaceInfo(EditeWorkSpaceInfo event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _changeProductTheme(ChangeProductTheme event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
  _changeThemeColors(ChangeThemeColors event, Emitter<WorkspaceState> emit) =>
      _genericLoadingSuccess(() async { /* TODO implement */ }, emit);
}

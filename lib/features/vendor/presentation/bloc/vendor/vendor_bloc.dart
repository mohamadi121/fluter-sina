import 'dart:convert';
import 'dart:ui';

import 'package:asoud/core/models/comment_model.dart';
import 'package:asoud/core/models/theme_model.dart';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/ui/ui_status.dart';

import 'package:asoud/features/vendor/data/model/slider_model.dart';

part 'vendor_event.dart';
part 'vendor_state.dart';

class VendorBloc extends Bloc<VendorEvent, VendorState> {
  VendorBloc() : super(VendorState.initial()) {
    on<AddLogoEvent>(_setShopLogo);
    on<DeleteLogoEvent>(_deleteShopLogo);
    on<AddBackgroundEvent>(_setShopBackground);
    on<DeleteBackgroundEvent>(_deleteShopBackground);
    on<LoadSlider>(_getSlider);
    on<AddSliderEvent>(_setShopSlider);
    on<EditSliderEvent>(_editShopSlider);
    on<DeleteSliderEvent>(_deleteShopSlider);
    on<SelectTopColor>(_selectTopColor);
    on<SelectSecondColor>(_selectSecondColor);
    on<SelectBackColor>(_selectBackColor);
    on<SelectFontColor>(_selectFontColor);
    on<SelectSecondFontColor>(_selectSecondFontColor);
    on<SelectFontFamily>(_selectFontFamily);
    on<SelectTheme>(_setMarketTheme);
    on<LoadComments>(_getComments);
  }

  Future<void> _setShopLogo(AddLogoEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, logoFile: event.logoImage, status: const UiLoading()));
    // TODO: Implement logo upload functionality
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _deleteShopLogo(DeleteLogoEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, status: const UiLoading()));
    // TODO: Implement logo delete functionality
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _setShopBackground(AddBackgroundEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, backgroundFile: event.backgroundImage, status: const UiLoading()));
    // TODO: Implement background upload functionality
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _deleteShopBackground(DeleteBackgroundEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, status: const UiLoading()));
    // TODO: Implement background delete functionality
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _getSlider(LoadSlider event, Emitter<VendorState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    // TODO: Implement slider loading
    emit(state.copyWith(status: const UiSuccess(), sliderList: []));
  }

  Future<void> _setShopSlider(AddSliderEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, status: const UiLoading()));
    // TODO: Implement slider addition
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _editShopSlider(EditSliderEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, status: const UiLoading()));
    // TODO: Implement slider editing
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _deleteShopSlider(DeleteSliderEvent event, Emitter<VendorState> emit) async {
    emit(state.copyWith(id: event.id, status: const UiLoading()));
    // TODO: Implement slider deletion
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _selectTopColor(SelectTopColor event, Emitter<VendorState> emit) async {
    emit(state.copyWith(topColor: event.topColor));
  }

  Future<void> _selectSecondColor(SelectSecondColor event, Emitter<VendorState> emit) async {
    emit(state.copyWith(secondColor: event.secondColor));
  }

  Future<void> _selectBackColor(SelectBackColor event, Emitter<VendorState> emit) async {
    emit(state.copyWith(backColor: event.backColor));
  }

  Future<void> _selectFontColor(SelectFontColor event, Emitter<VendorState> emit) async {
    emit(state.copyWith(fontColor: event.fontColor));
  }

  Future<void> _selectSecondFontColor(SelectSecondFontColor event, Emitter<VendorState> emit) async {
    emit(state.copyWith(secondFontColor: event.secondFontColor));
  }

  Future<void> _selectFontFamily(SelectFontFamily event, Emitter<VendorState> emit) async {
    emit(state.copyWith(fontFamily: event.fontFamily));
  }

  Future<void> _setMarketTheme(SelectTheme event, Emitter<VendorState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    // TODO: Implement theme setting
    emit(state.copyWith(status: const UiSuccess()));
  }

  Future<void> _getComments(LoadComments event, Emitter<VendorState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    // TODO: Implement comments loading
    emit(state.copyWith(status: const UiSuccess(), commentList: []));
  }
}

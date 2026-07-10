import 'dart:io';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/logging/app_logger.dart';
import 'package:asood/features/inquiry/data/model/inquiry_card_model.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'inquiry_event.dart';
part 'inquiry_state.dart';

class InquiryBloc extends Bloc<InquiryEvent, InquiryState> {
  final InquiryRepo inquiryRepo;
  InquiryBloc(this.inquiryRepo) : super(InquiryState.initial()) {
    on<InquirySubmit>(_inquirySubmit);
    on<InquiryTypeSwitch>(_inquiryTypeSwitch);
    on<InquiryAddImage>(_inquiryAddImage);
    on<InquiryRemoveImage>(_inquiryRemoveImage);
  }

  // Full inquiry flow: create -> upload each image -> send. Images used to be
  // dropped entirely (the old create ignored them); now they are uploaded to
  // the created inquiry before it is sent.
  _inquirySubmit(InquirySubmit event, Emitter<InquiryState> emit) async {
    emit(state.copyWith(status: CWSStatus.loading));

    final body = {
      'type': event.inquiryType,
      'name': event.inquiryTitle,
      if (event.inquiryDetails != null)
        'technical_detail': event.inquiryDetails,
      if (event.inquiryAmount != null) 'amount': event.inquiryAmount.toString(),
      if (event.inquiryUnit != null) 'unit': event.inquiryUnit,
      'expiry': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };

    try {
      final createRes = await inquiryRepo.createInquiry(body);
      if (createRes is! Success) {
        emit(state.copyWith(status: CWSStatus.failure));
        return;
      }

      final id = (createRes.response as Map?)?['id']?.toString();
      if (id == null) {
        AppLogger.error('inquiry', 'create response missing id');
        emit(state.copyWith(status: CWSStatus.failure));
        return;
      }

      for (final image in event.inquiryImages ?? const <File>[]) {
        final upload = await inquiryRepo.uploadImage(id, XFile(image.path));
        if (upload is! Success) {
          AppLogger.warning('inquiry', 'image upload failed for inquiry $id');
        }
      }

      final sendRes = await inquiryRepo.sendInquiry(id);
      emit(
        state.copyWith(
          status: sendRes is Success ? CWSStatus.success : CWSStatus.failure,
        ),
      );
    } catch (e, st) {
      AppLogger.error('inquiry', 'submit failed', e, st);
      emit(state.copyWith(status: CWSStatus.failure));
    }
  }

  _inquiryTypeSwitch(
    InquiryTypeSwitch event,
    Emitter<InquiryState> emit,
  ) async {
    emit(state.copyWith(inquiryType: event.inquiryType));
  }

  _inquiryAddImage(InquiryAddImage event, Emitter<InquiryState> emit) async {
    final inquiryImages = List<File>.from(state.inquiryImages)
      ..add(event.image);

    emit(state.copyWith(inquiryImages: inquiryImages));
  }

  _inquiryRemoveImage(
    InquiryRemoveImage event,
    Emitter<InquiryState> emit,
  ) async {
    final inquiryImages = List<File>.from(state.inquiryImages)
      ..removeAt(event.index);

    emit(state.copyWith(inquiryImages: inquiryImages));
  }
}

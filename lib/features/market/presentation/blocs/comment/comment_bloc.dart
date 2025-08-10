import 'package:asoud/core/models/comment_model.dart';
import 'package:bloc/bloc.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/ui/ui_status.dart';

part 'comment_event.dart';
part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  CommentBloc() : super(CommentState.initial()) {
    on<LoadCommentsEvent>(_load);
    on<AddCommentEvent>(_add);
  }

  Future<void> _load(LoadCommentsEvent event, Emitter<CommentState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    // TODO: Implement comments loading
    emit(state.copyWith(status: const UiSuccess(), commentList: []));
  }

  Future<void> _add(AddCommentEvent event, Emitter<CommentState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    // TODO: Implement comment adding
    emit(state.copyWith(status: const UiSuccess()));
  }
}

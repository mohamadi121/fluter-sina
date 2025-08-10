part of 'comment_bloc.dart';

class CommentState {
  final List<CommentModel> commentList;
  final UiStatus status;
  final bool posting;
  final String error;

  const CommentState({required this.commentList, required this.status, required this.posting, required this.error});

  factory CommentState.initial() {
    return const CommentState(commentList: [], status: UiIdle(), posting: false, error: '');
  }

  CommentState copyWith({List<CommentModel>? commentList, UiStatus? status, bool? posting, String? error}) {
    return CommentState(
      commentList: commentList ?? this.commentList,
      status: status ?? this.status,
      posting: posting ?? this.posting,
      error: error ?? this.error,
    );
  }
}

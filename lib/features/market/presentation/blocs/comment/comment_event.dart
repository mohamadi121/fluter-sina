part of 'comment_bloc.dart';

sealed class CommentEvent {
  const CommentEvent();
}

class LoadCommentsEvent extends CommentEvent {
  final String marketId;
  const LoadCommentsEvent({required this.marketId});
}

class AddCommentEvent extends CommentEvent {
  final String marketId;
  final String content;
  const AddCommentEvent({required this.marketId, required this.content});
}

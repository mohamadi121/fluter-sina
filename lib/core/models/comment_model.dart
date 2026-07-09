/// Comment as served by the backend's django-comments-xtd integration
/// (`GET user/comment/comments/{content_type}/{object_id}/`, bare list —
/// fields: id, user, comment, submit_date, parent_id, level, children).
class CommentModel {
  final int? id;
  final int? user;
  final String? comment;
  final String? submitDate;
  final int? parentId;
  final int? level;
  final List<CommentModel> children;

  const CommentModel({
    this.id,
    this.user,
    this.comment,
    this.submitDate,
    this.parentId,
    this.level,
    this.children = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    return CommentModel(
      id: json['id'],
      user: json['user'],
      comment: json['comment']?.toString(),
      submitDate: json['submit_date']?.toString(),
      parentId: json['parent_id'],
      level: json['level'],
      children:
          rawChildren is List
              ? rawChildren
                  .whereType<Map>()
                  .map(
                    (e) => CommentModel.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'comment': comment,
      'submit_date': submitDate,
      'parent_id': parentId,
      'level': level,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}

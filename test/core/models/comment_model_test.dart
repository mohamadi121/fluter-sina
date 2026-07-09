import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/models/comment_model.dart';

void main() {
  test('parses the real backend comment shape including nested children', () {
    final model = CommentModel.fromJson({
      'id': 12,
      'user': 3,
      'comment': 'محصول خوبی بود',
      'submit_date': '2026-07-01T10:00:00Z',
      'parent_id': 12,
      'level': 0,
      'children': [
        {
          'id': 13,
          'user': 5,
          'comment': 'ممنون',
          'submit_date': '2026-07-01T11:00:00Z',
          'parent_id': 12,
          'level': 1,
          'children': [],
        },
      ],
    });

    expect(model.id, 12);
    expect(model.user, 3);
    expect(model.comment, 'محصول خوبی بود');
    expect(model.children, hasLength(1));
    expect(model.children.single.comment, 'ممنون');
    expect(model.children.single.level, 1);
  });

  test('tolerates missing optional fields', () {
    final model = CommentModel.fromJson({'id': 1, 'comment': 'x'});

    expect(model.user, isNull);
    expect(model.children, isEmpty);
  });
}

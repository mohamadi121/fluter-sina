import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:asood/features/product/blocs/product_detail_cubit.dart';

class _FakeProductRepo implements ProductRepository {
  dynamic detailRes;
  dynamic commentsRes;
  dynamic createCommentRes;
  final createdComments = <Map<String, dynamic>>[];

  @override
  Future getProductDetail(String productId) async => detailRes;

  @override
  Future getProductComments(String productId) async => commentsRes;

  @override
  Future createComment({
    required String contentType,
    required String objectId,
    required String comment,
    int? parentId,
  }) async {
    createdComments.add({
      'content_type': contentType,
      'object_id': objectId,
      'comment': comment,
      'parent_id': parentId,
    });
    return createCommentRes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeProductRepo repo;
  late ProductDetailCubit cubit;

  setUp(() {
    repo = _FakeProductRepo();
    cubit = ProductDetailCubit(repo: repo);
  });

  tearDown(() => cubit.close());

  test('load fills detail and comments', () async {
    repo.detailRes = Success(
      code: 200,
      response: {'name': 'p1', 'shipping_cost': 5000},
    );
    repo.commentsRes = Success(
      code: 200,
      response: [
        {'id': 1, 'user': 2, 'comment': 'خوب'},
      ],
    );

    await cubit.load('prod-1');

    expect(cubit.state.status, ProductDetailStatus.ready);
    expect(cubit.state.detail['name'], 'p1');
    expect(cubit.state.comments, hasLength(1));
  });

  test('load failure surfaces error', () async {
    repo.detailRes = Failure(
      code: 404,
      errorResponse: 'Product not found',
      kind: FailureKind.notFound,
    );

    await cubit.load('nope');

    expect(cubit.state.status, ProductDetailStatus.failure);
    expect(cubit.state.error, 'Product not found');
  });

  test('sendComment posts product comment and refreshes thread', () async {
    repo.detailRes = Success(code: 200, response: {'name': 'p1'});
    repo.commentsRes = Success(code: 200, response: []);
    await cubit.load('prod-1');

    repo.createCommentRes = Success(
      code: 201,
      response: {'message': 'Comment created', 'id': 9},
    );
    repo.commentsRes = Success(
      code: 200,
      response: [
        {'id': 9, 'comment': 'hi'},
      ],
    );

    await cubit.sendComment('hi');

    expect(repo.createdComments.single['content_type'], 'product');
    expect(repo.createdComments.single['object_id'], 'prod-1');
    expect(cubit.state.comments, hasLength(1));
  });

  test('reply passes parent id', () async {
    repo.detailRes = Success(code: 200, response: {});
    repo.commentsRes = Success(code: 200, response: []);
    await cubit.load('prod-1');
    repo.createCommentRes = Success(code: 201, response: {'id': 10});

    await cubit.sendComment('پاسخ', parentId: 4);

    expect(repo.createdComments.single['parent_id'], 4);
  });

  test('empty comment is not sent', () async {
    repo.detailRes = Success(code: 200, response: {});
    repo.commentsRes = Success(code: 200, response: []);
    await cubit.load('prod-1');

    await cubit.sendComment('   ');

    expect(repo.createdComments, isEmpty);
  });
}

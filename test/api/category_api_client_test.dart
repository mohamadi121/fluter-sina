import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:asoud/api/category_api_client.dart';
import 'package:asoud/core/models/dto/base_response_dto.dart';
import 'package:asoud/core/models/dto/category_dto.dart';

void main() {
  group('Category API Client Contract Tests', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late CategoryApiClient categoryApiClient;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.asoud.ir/api/v1'));
      dioAdapter = DioAdapter(dio: dio);
      categoryApiClient = CategoryApiClient(dio);
    });

    group('Category Groups', () {
      test('should get category groups with correct headers', () async {
        // Arrange
        final expectedResponse = {
          'success': true,
          'code': 200,
          'data': [
            {
              'id': '3bbd860f-93bf-4636-b288-86b9c07e8138',
              'title': 'سخت افزار'
            }
          ],
          'message': 'Data retrieved successfully'
        };

        dioAdapter.onGet(
          '/category/group/list/',
          (server) => server.reply(200, expectedResponse),
          headers: Matchers.any,
        );

        // Act
        final result = await categoryApiClient.getCategoryGroups();

        // Assert
        expect(result.success, isTrue);
        expect(result.code, equals(200));
        expect(result.data, isNotNull);
        expect(result.data!.length, equals(1));
        expect(result.data!.first.id, equals('3bbd860f-93bf-4636-b288-86b9c07e8138'));
        expect(result.data!.first.title, equals('سخت افزار'));
        
        // Verify authorization header was sent
        final history = dioAdapter.history;
        expect(history.length, equals(1));
        expect(history.first.request.headers, containsPair('authorization', isNotNull));
      });
    });

    group('Categories by Group', () {
      test('should get categories with correct path parameter', () async {
        // Arrange
        const groupId = '3bbd860f-93bf-4636-b288-86b9c07e8138';
        final expectedResponse = {
          'success': true,
          'code': 200,
          'data': [
            {
              'id': 'cat-1',
              'title': 'لپ تاپ',
              'description': 'انواع لپ تاپ',
              'group_id': groupId
            }
          ],
          'message': 'Categories retrieved successfully'
        };

        dioAdapter.onGet(
          '/category/list/$groupId',
          (server) => server.reply(200, expectedResponse),
          headers: Matchers.any,
        );

        // Act
        final result = await categoryApiClient.getCategories(groupId);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.length, equals(1));
        expect(result.data!.first.id, equals('cat-1'));
        expect(result.data!.first.title, equals('لپ تاپ'));
        expect(result.data!.first.groupId, equals(groupId));
        
        // Verify correct path was called
        final history = dioAdapter.history;
        expect(history.length, equals(1));
        expect(history.first.request.path, equals('/category/list/$groupId'));
      });

      test('should handle group not found error', () async {
        // Arrange
        const invalidGroupId = 'invalid-group-id';
        final errorResponse = {
          'success': false,
          'code': 404,
          'error': 'Group Not Found'
        };

        dioAdapter.onGet(
          '/category/list/$invalidGroupId',
          (server) => server.reply(200, errorResponse),
          headers: Matchers.any,
        );

        // Act
        final result = await categoryApiClient.getCategories(invalidGroupId);

        // Assert
        expect(result.success, isFalse);
        expect(result.code, equals(404));
        expect(result.error, equals('Group Not Found'));
      });
    });
  });
}

#!/bin/bash

echo "🎯 Phase 0 - Day 1: Testing Infrastructure Setup"
echo "================================================"

# Step 1: Update pubspec.yaml with test dependencies
echo ""
echo "📦 Step 1: Adding test dependencies to pubspec.yaml..."

# Backup current pubspec.yaml
cp pubspec.yaml pubspec.yaml.backup

# Add test dependencies
cat >> pubspec.yaml << 'YAML'

  # Testing dependencies (Phase 0)
  mockito: ^5.4.4
  bloc_test: ^9.1.5
  faker: ^2.1.0
  http_mock_adapter: ^0.6.0
YAML

echo "✅ Test dependencies added!"

# Step 2: Create test folder structure
echo ""
echo "📁 Step 2: Creating test folder structure..."

mkdir -p test/unit/core/api
mkdir -p test/unit/core/utils
mkdir -p test/unit/features/auth/data/models
mkdir -p test/unit/features/auth/data/repository
mkdir -p test/unit/features/auth/presentation/blocs
mkdir -p test/unit/features/cart/presentation/blocs
mkdir -p test/unit/features/chat/presentation/blocs
mkdir -p test/unit/mocks
mkdir -p test/widget/auth
mkdir -p test/widget/cart
mkdir -p test/widget/common
mkdir -p test/integration
mkdir -p test/fixtures
mkdir -p test/helpers

echo "✅ Test folder structure created!"

# Step 3: Create test helper file
echo ""
echo "🔧 Step 3: Creating test helpers..."

cat > test/helpers/test_helper.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';

/// Test helper utilities
class TestHelpers {
  /// Setup for all tests
  static void setupAll() {
    // Global test setup
  }
  
  /// Tear down
  static void tearDownAll() {
    // Cleanup
  }
  
  /// Create mock auth response
  static Map<String, dynamic> mockAuthResponse() {
    return {
      'token': 'test_token_123456',
      'user': {
        'id': '1',
        'mobile_number': '09123456789',
        'name': 'Test User',
      }
    };
  }
  
  /// Create mock product data
  static Map<String, dynamic> mockProductData() {
    return {
      'id': '1',
      'name': 'Test Product',
      'price': 99.99,
      'main_price': 129.99,
      'description': 'Test product description',
    };
  }
  
  /// Create mock cart data
  static Map<String, dynamic> mockCartData() {
    return {
      'items': [
        {
          'id': '1',
          'product': mockProductData(),
          'quantity': 2,
        }
      ],
      'total': 199.98,
    };
  }
}
DART

echo "✅ Test helpers created!"

# Step 4: Create example unit test
echo ""
echo "🧪 Step 4: Creating example unit test..."

cat > test/unit/core/api/dio_client_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioClient Tests', () {
    test('should initialize properly', () {
      // TODO: Implement test
      expect(true, true);
    });
    
    test('should handle GET requests', () {
      // TODO: Implement test
      expect(true, true);
    });
    
    test('should handle POST requests', () {
      // TODO: Implement test
      expect(true, true);
    });
  });
}
DART

echo "✅ Example unit test created!"

# Step 5: Create example widget test
echo ""
echo "🎨 Step 5: Creating example widget test..."

cat > test/widget/common/loading_indicator_test.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Loading indicator should display', (tester) async {
    // Build widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    
    // Verify
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
DART

echo "✅ Example widget test created!"

# Step 6: Create fixtures
echo ""
echo "📝 Step 6: Creating test fixtures..."

cat > test/fixtures/auth_response.json << 'JSON'
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "mobile_number": "09123456789",
    "name": "تست کاربر"
  }
}
JSON

cat > test/fixtures/product_list.json << 'JSON'
{
  "results": [
    {
      "id": "1",
      "name": "محصول تستی 1",
      "price": 99.99,
      "main_price": 129.99
    },
    {
      "id": "2",
      "name": "محصول تستی 2",
      "price": 199.99,
      "main_price": 249.99
    }
  ]
}
JSON

echo "✅ Test fixtures created!"

echo ""
echo "================================================"
echo "✅ Phase 0 Day 1 Complete!"
echo ""
echo "Next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter test"
echo "3. Check: test/ folder structure"
echo ""

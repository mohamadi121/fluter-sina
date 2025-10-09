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

# Phase 4-5 API Migration Guide

## Overview

This document outlines the complete Phase 4-5 migration from ad-hoc Dio calls to typed API clients with DTOs, unified error handling, and comprehensive test coverage.

## Migration Summary

### ✅ Completed
- Environment configuration with dart-define support
- Enhanced DioClient with AppError system  
- Material 3 theming and accessibility widgets
- Responsive design helpers
- Typed API clients for all services (Auth, Category, Product, Cart, Payment, User, Market, Advertisement)
- DTOs with json_serializable for all API endpoints
- Contract tests for API client validation
- CI/CD pipeline with automated testing
- Unified AsoudApiService for centralized API access

### 🔄 In Progress
- Service wrapper classes for business logic
- Repository layer migration
- BLoC integration with new API services
- Integration tests for E2E workflows

### 📋 Pending
- Widget test updates for new components
- Golden test validation across themes
- Documentation updates
- Performance optimization

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                   │
├─────────────────────────────────────────────────────────────┤
│  BLoCs/Cubits  │  Widgets  │  Pages  │  Material 3 Theme   │
├─────────────────────────────────────────────────────────────┤
│                         Service Layer                       │
├─────────────────────────────────────────────────────────────┤
│  Product      │  Cart       │  Payment    │  User           │
│  Service      │  Service    │  Service    │  Service        │
├─────────────────────────────────────────────────────────────┤
│                       API Client Layer                      │
├─────────────────────────────────────────────────────────────┤
│              AsoudApiService (Unified API)                  │
├─────────────────────────────────────────────────────────────┤
│  Auth API   │  Product API │  Cart API │  Payment API      │
│  Client     │  Client      │  Client   │  Client           │
├─────────────────────────────────────────────────────────────┤
│                         Network Layer                       │
├─────────────────────────────────────────────────────────────┤
│           DioClient + AppError + Retry Logic                │
├─────────────────────────────────────────────────────────────┤
│                      DTO & Model Layer                      │
├─────────────────────────────────────────────────────────────┤
│  AuthDto │ ProductDto │ CartDto │ PaymentDto │ UserDto       │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Unified API Service

```dart
// Central point for all API clients
final apiService = AsoudApiService(dioClient);

// Access specific clients
final authResponse = await apiService.auth.sendVerificationCode(request);
final products = await apiService.product.getProducts();
final cart = await apiService.cart.getCart();
```

### 2. Typed DTOs

All API requests and responses use strongly typed DTOs:

```dart
// Request DTO
final authRequest = AuthRequestDto(mobileNumber: phoneNumber);

// Response DTO with proper typing
final AuthResponseDto response = await apiService.auth.sendVerificationCode(authRequest);

// Type-safe access to data
final String token = response.data?.token ?? '';
```

### 3. Enhanced Error Handling

```dart
try {
  final response = await apiService.product.getProducts();
  // Handle success
} catch (e) {
  if (e is AppError) {
    switch (e.type) {
      case AppErrorType.network:
        // Handle network error
        break;
      case AppErrorType.server:
        // Handle server error
        break;
      case AppErrorType.unauthorized:
        // Handle auth error
        break;
    }
  }
}
```

### 4. Service Layer Pattern

```dart
class ProductService {
  final AsoudApiService apiService;
  
  ProductService(this.apiService);

  Future<ProductListResponseDto> getProducts({
    String? search,
    String? category,
    // ... other parameters
  }) async {
    try {
      return await apiService.product.getProducts(
        search: search,
        category: category,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
```

## API Endpoints Coverage

### Auth API
- ✅ POST `/api/v1/auth/login/create/` - Send verification code
- ✅ POST `/api/v1/auth/login/verify/` - Verify SMS code  
- ✅ POST `/api/v1/auth/logout/` - Logout user

### Category API
- ✅ GET `/api/v1/category/list/` - Get categories
- ✅ GET `/api/v1/category/sub/list/{categoryId}` - Get subcategories
- ✅ GET `/api/v1/region/country/list/` - Get countries
- ✅ GET `/api/v1/region/province/list/{countryId}` - Get provinces
- ✅ GET `/api/v1/region/city/list/{provinceId}` - Get cities

### Product API
- ✅ GET `/api/v1/user/product/list/` - Get products (public)
- ✅ GET `/api/v1/user/product/{productId}/` - Get product details
- ✅ GET `/api/v1/user/product/market/{marketId}/` - Get market products
- ✅ POST `/api/v1/owner/product/create/` - Create product
- ✅ GET `/api/v1/owner/product/list/{marketId}/` - Get owner products
- ✅ PUT `/api/v1/owner/product/update/{productId}/` - Update product
- ✅ DELETE `/api/v1/owner/product/delete/{productId}/` - Delete product

### Cart API
- ✅ GET `/api/v1/user/orders` - Get cart contents
- ✅ POST `/api/v1/user/add_item` - Add item to cart
- ✅ PUT `/api/v1/user/update_item/{itemId}` - Update cart item
- ✅ DELETE `/api/v1/user/remove_item/{itemId}` - Remove cart item
- ✅ POST `/api/v1/user/checkout` - Checkout cart
- ✅ POST `/api/v1/user/order/create` - Create order
- ✅ GET `/api/v1/user/order/list` - Get orders

### Payment API  
- ✅ POST `/api/v1/user/payments/create/` - Create payment
- ✅ GET `/api/v1/user/payments/` - Get payment history
- ✅ GET `/api/v1/user/payments/{paymentId}/` - Get payment details
- ✅ GET `/api/v1/user/payments/verify/` - Verify payment

### User API
- ✅ GET `/api/v1/user/profile/` - Get user profile
- ✅ PUT `/api/v1/user/profile/update/` - Update profile
- ✅ GET `/api/v1/user/documents/` - Get documents
- ✅ POST `/api/v1/user/documents/upload/` - Upload document

### Market API
- ✅ POST `/api/v1/owner/market/create/` - Create market
- ✅ GET `/api/v1/owner/market/list/` - Get owner markets
- ✅ GET `/api/v1/owner/market/{marketId}/` - Get market details
- ✅ PUT `/api/v1/owner/market/update/{marketId}/` - Update market
- ✅ POST `/api/v1/owner/market/location/create/` - Create location

### Advertisement API
- ✅ POST `/api/v1/advertisements/create` - Create advertisement
- ✅ GET `/api/v1/advertisements/` - Get advertisements
- ✅ GET `/api/v1/advertisements/{adId}` - Get advertisement details
- ✅ GET `/api/v1/advertisements/self` - Get user advertisements
- ✅ PUT `/api/v1/advertisements/{adId}/update` - Update advertisement

## Migration Steps

### Step 1: Update Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  # Existing dependencies...
  retrofit: ^4.0.1
  json_serializable: ^6.7.1
  
dev_dependencies:
  # Existing dev dependencies...
  retrofit_generator: ^8.0.4
  json_annotation: ^4.8.1
  http_mock_adapter: ^0.6.0
```

### Step 2: Generate Code

Run code generation:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Update Service Locator

Replace existing locator with migrated version:
```dart
// Use locator_migrated.dart instead of locator.dart
import 'package:asoud/locator_migrated.dart';

void main() async {
  await locatorSetup();
  runApp(MyApp());
}
```

### Step 4: Migrate Feature Services

Replace legacy API services with new typed services:

```dart
// OLD: Direct DioClient usage
class LegacyAuthService {
  final DioClient dioClient;
  
  Future<Map<String, dynamic>> userAuth(String number) async {
    var body = {"mobile_number": number};
    try {
      Response res = await dioClient.postData(endpoint, body);
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }
}

// NEW: Typed API service
class AuthService {
  final AsoudApiService apiService;
  
  Future<AuthResponseDto> sendVerificationCode(String phoneNumber) async {
    try {
      final request = AuthRequestDto(mobileNumber: phoneNumber);
      return await apiService.auth.sendVerificationCode(request);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
```

### Step 5: Update BLoC Integration

```dart
// OLD: Using legacy service
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApiService authService;
  
  AuthBloc(this.authService) : super(AuthInitial()) {
    on<SendVerificationCode>((event, emit) async {
      final result = await authService.userAuth(event.phoneNumber);
      if (result['success']) {
        emit(CodeSentState());
      } else {
        emit(AuthErrorState(result['error']));
      }
    });
  }
}

// NEW: Using typed service
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  
  AuthBloc(this.authService) : super(AuthInitial()) {
    on<SendVerificationCode>((event, emit) async {
      try {
        emit(AuthLoadingState());
        final response = await authService.sendVerificationCode(event.phoneNumber);
        emit(CodeSentState(response.message));
      } catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });
  }
}
```

## Testing Strategy

### 1. Contract Tests

Validate API client request/response format:
```dart
testWidgets('Auth API contract validation', (tester) async {
  final mockAdapter = DioAdapter(dio: dio);
  
  mockAdapter.onPost('/api/v1/auth/login/create/').reply(200, {
    'success': true,
    'code': 200,
    'data': {'token': 'test_token'},
    'message': 'Success'
  });
  
  final response = await authApiClient.sendVerificationCode(
    AuthRequestDto(mobileNumber: '09123456789')
  );
  
  expect(response.success, isTrue);
  expect(response.data?.token, equals('test_token'));
});
```

### 2. Integration Tests

Test complete workflows:
```dart
testWidgets('Complete shopping flow', (tester) async {
  // 1. Login
  final authResponse = await apiService.auth.sendVerificationCode(authRequest);
  expect(authResponse.success, isTrue);
  
  // 2. Browse products
  final products = await apiService.product.getProducts();
  expect(products.data, isNotEmpty);
  
  // 3. Add to cart
  final cartResponse = await apiService.cart.addItem(cartItem);
  expect(cartResponse.success, isTrue);
  
  // 4. Checkout
  final orderResponse = await apiService.cart.checkout();
  expect(orderResponse.success, isTrue);
});
```

### 3. Widget Tests

Test UI components with new services:
```dart
testWidgets('Product list displays correctly', (tester) async {
  when(mockProductService.getProducts()).thenAnswer(
    (_) async => ProductListResponseDto(
      success: true,
      code: 200,
      data: [ProductListItemDto(...)],
      message: 'Success',
    ),
  );
  
  await tester.pumpWidget(ProductListPage());
  await tester.pumpAndSettle();
  
  expect(find.byType(ProductCard), findsWidgets);
});
```

## Environment Configuration

### Development
```bash
flutter run --dart-define=ENVIRONMENT=development \
           --dart-define=API_BASE_URL=http://localhost:8000 \
           --dart-define=DEBUG_MODE=true
```

### Staging
```bash
flutter run --dart-define=ENVIRONMENT=staging \
           --dart-define=API_BASE_URL=https://staging.asoud.ir \
           --dart-define=DEBUG_MODE=false
```

### Production
```bash
flutter run --dart-define=ENVIRONMENT=production \
           --dart-define=API_BASE_URL=https://api.asoud.ir \
           --dart-define=DEBUG_MODE=false
```

## Error Handling Strategy

### 1. Network Errors
```dart
try {
  final response = await apiService.product.getProducts();
} catch (e) {
  if (e is AppError && e.type == AppErrorType.network) {
    // Show retry button
    showSnackBar('خطای شبکه. لطفا دوباره تلاش کنید.');
  }
}
```

### 2. Server Errors
```dart
catch (e) {
  if (e is AppError && e.type == AppErrorType.server) {
    if (e.statusCode == 500) {
      showSnackBar('خطای سرور. لطفا بعدا تلاش کنید.');
    }
  }
}
```

### 3. Authentication Errors
```dart
catch (e) {
  if (e is AppError && e.type == AppErrorType.unauthorized) {
    // Redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

## Performance Considerations

### 1. Response Caching
```dart
class ProductService {
  final Map<String, ProductListResponseDto> _cache = {};
  
  Future<ProductListResponseDto> getProducts({String? category}) async {
    final cacheKey = 'products_$category';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    final response = await apiService.product.getProducts(category: category);
    _cache[cacheKey] = response;
    return response;
  }
}
```

### 2. Request Debouncing
```dart
class SearchService {
  Timer? _debounceTimer;
  
  void searchProducts(String query, Function(List<Product>) onResults) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      final response = await apiService.product.getProducts(search: query);
      onResults(response.data ?? []);
    });
  }
}
```

### 3. Pagination
```dart
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  int _currentPage = 1;
  bool _hasNextPage = true;
  
  void _onLoadMore(LoadMoreProducts event, emit) async {
    if (!_hasNextPage) return;
    
    final response = await productService.getProducts(page: _currentPage + 1);
    if (response.data?.isNotEmpty == true) {
      _currentPage++;
      emit(ProductListLoaded([...state.products, ...response.data!]));
    } else {
      _hasNextPage = false;
    }
  }
}
```

## Migration Checklist

### Phase 4 - API Integration ✅
- [x] Create all DTO classes with json_serializable
- [x] Implement all API clients with Retrofit
- [x] Create unified AsoudApiService
- [x] Build service wrapper classes
- [x] Update service locator
- [x] Create migrated auth service example

### Phase 5 - E2E Verification 🔄
- [ ] Replace auth service in AuthBloc
- [ ] Replace product service in ProductBloc  
- [ ] Replace market service in MarketBloc
- [ ] Add cart management BLoC
- [ ] Add payment management BLoC
- [ ] Create integration tests
- [ ] Update widget tests
- [ ] Validate golden tests

### Documentation & Polish 📋
- [ ] Update API documentation
- [ ] Create migration guide videos
- [ ] Performance optimization
- [ ] Accessibility validation
- [ ] Final E2E testing

## Troubleshooting

### Common Issues

1. **Code Generation Errors**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Missing Dependencies**
   ```bash
   flutter pub deps
   flutter pub get
   ```

3. **Type Errors**
   - Ensure all DTOs have proper JsonSerializable annotations
   - Check import statements for generated files
   - Verify API client interfaces match backend contracts

4. **Network Errors**
   - Check EnvConfig.baseUrl is correct
   - Verify token handling in DioClient
   - Test with real backend endpoints

## Conclusion

This Phase 4-5 migration provides:

✅ **Type Safety**: All API calls are strongly typed with compile-time validation  
✅ **Error Handling**: Unified AppError system with proper error recovery  
✅ **Maintainability**: Clear separation of concerns with service layer  
✅ **Testability**: Comprehensive testing strategy with contract validation  
✅ **Performance**: Caching, pagination, and request optimization  
✅ **Developer Experience**: Better IDE support, auto-completion, and debugging

The migration maintains backward compatibility while providing a clear path forward for all Flutter development with the Django backend.

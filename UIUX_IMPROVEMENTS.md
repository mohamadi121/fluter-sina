# 🚀 Asoud Flutter App - Backend Contract Alignment & UI/UX Improvements

این مستند تغییرات و بهبودهای اعمال شده روی اپلیکیشن Flutter آسود را شرح می‌دهد که شامل تطبیق کامل با قراردادهای backend Django و بهبودهای UI/UX است.

## 📋 خلاصه تغییرات

### 🎯 **مشکلات حل شده:**

1. **Backend Contract Alignment** - تطبیق کامل با API Django
2. **Typed API Client** - کلاینت API با Retrofit و DTOs  
3. **Error Handling** - مدیریت یکپارچه خطاها
4. **Configuration Management** - پیکربندی environment ها
5. **Accessibility** - پشتیبانی از کاربران با نیازهای ویژه
6. **Material 3 Theme** - پیاده‌سازی کامل Material 3
7. **Responsive Design** - پشتیبانی از اندازه‌های مختلف صفحه
8. **Contract Tests** - تست‌های تأیید صحت قراردادها
9. **Performance** - بهینه‌سازی عملکرد

---

## 🔗 **Backend Contract Analysis**

### **Authentication Scheme:**
- **Header Format**: `Authorization: Token <token>` (NOT Bearer)
- **Token Source**: `/api/v1/user/pin/verify/` endpoint
- **Request Format**: `multipart/form-data` for auth endpoints

### **Response Envelope:**
```json
// Success Response
{
  "success": true,
  "code": 200,
  "data": {...},
  "message": "Success message"
}

// Error Response  
{
  "success": false,
  "code": 401,
  "error": {
    "code": "error_code",
    "detail": "Error detail"
  }
}
```

### **Frontend Consumer Table:**

| Method | Path | Auth | Request | Response | Status Codes |
|--------|------|------|---------|----------|--------------|
| POST | `/user/pin/create/` | None | `{mobile_number}` | `{success, code, data: {}, message}` | 200, 500 |
| POST | `/user/pin/verify/` | None | `{mobile_number, pin}` | `{success, code, data: {token}, message}` | 200, 401 |
| GET | `/category/group/list/` | Token | - | `{success, code, data: [{id, title}], message}` | 200 |
| GET | `/category/list/{groupId}` | Token | - | `{success, code, data: [...], message}` | 200, 404 |

---

## 🗂️ **ساختار فایل‌های جدید:**

```
lib/
├── api/                                # Typed API clients
│   ├── auth_api_client.dart           # Retrofit auth client
│   ├── category_api_client.dart       # Retrofit category client
│   └── services/                      # Business logic services  
│       ├── auth_service.dart          # Auth service with error handling
│       └── category_service.dart      # Category service
├── core/
│   ├── config/
│   │   └── env_config.dart           # Environment configuration
│   ├── network/
│   │   ├── dio_client.dart           # Enhanced HTTP client
│   │   └── app_error.dart            # Error handling system
│   ├── models/dto/                   # Data Transfer Objects
│   │   ├── base_response_dto.dart    # Base response envelope
│   │   ├── auth_dto.dart             # Auth DTOs
│   │   └── category_dto.dart         # Category DTOs
│   ├── mappers/
│   │   └── auth_mapper.dart          # DTO ↔ Domain mappers
│   ├── utils/
│   │   └── responsive_helper.dart    # Responsive utilities
│   └── widgets/
│       └── accessibility_widgets.dart # Accessible components
├── test/
│   ├── api/                          # Contract tests
│   │   ├── auth_api_client_test.dart # Auth API contract tests
│   │   └── category_api_client_test.dart # Category API tests
│   └── widget/                       # Widget tests
└── scripts/                          # Build automation
    ├── dev_build.sh                  # Development build
    ├── prod_build.sh                 # Production build
    └── rollback.sh                   # Rollback script
```

---

## 🔧 **راه‌اندازی و اجرا**

### Prerequisites:
```bash
flutter --version  # >= 3.7.0
dart --version     # >= 3.0.0
```

### 1. نصب Dependencies و Code Generation:
```bash
cd /home/devops/projects/fluter-sina
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 2. اجرای Development:
```bash
# استفاده از اسکریپت آماده
./scripts/dev_build.sh

# یا دستی:
flutter run \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=BASE_URL=https://api.asoud.ir \
  --dart-define=ENABLE_LOGS=true \
  --dart-define=UIUX_PREVIEW=true
```

### 3. Build Production:
```bash
# استفاده از اسکریپت آماده
./scripts/prod_build.sh

# یا دستی:
flutter build apk \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=BASE_URL=https://api.asoud.ir \
  --dart-define=ENABLE_LOGS=false \
  --release
```

---

## 🧪 **تست‌ها**

### اجرای همه تست‌ها:
```bash
flutter test
```

### تست‌های Contract (API):
```bash
flutter test test/api/
```

### تست‌های Widget:
```bash
flutter test test/widget/
```

### تحلیل کد:
```bash
flutter analyze
```

---

## 🔗 **تطبیق با Backend**

### 1. **Typed API Clients**
- استفاده از **Retrofit** برای type-safe API calls
- **DTOs** با `json_serializable` برای serialization دقیق
- **Services** برای business logic و error handling

### 2. **Authentication**
```dart
// صحیح - مطابق با backend
headers['Authorization'] = 'Token $token';

// نادرست
headers['Authorization'] = 'Bearer $token';
```

### 3. **Error Mapping**
```dart
// مطابق با response envelope backend
BaseResponseDto<T> response = await apiClient.call();
if (!response.success) {
  throw _mapErrorFromResponse(response);
}
```

### 4. **Request Formats**
```dart
// Auth endpoints: multipart/form-data
@POST('/user/pin/create/')
@MultiPart()
Future<BaseResponseDto<EmptyDto>> createPin(
  @Part('mobile_number') String mobileNumber,
);

// Other endpoints: application/json
@GET('/category/group/list/')
Future<BaseResponseDto<List<CategoryGroupDto>>> getCategoryGroups();
```

---

## 🎨 **ویژگی‌های UI/UX**

### 1. **Material 3 Theme**
- ColorScheme جدید
- Typography بهبود یافته
- Component theming
- Dark mode support

### 2. **Accessibility**
- Semantic labels کامل
- Focus management
- Touch targets ≥48dp
- Screen reader support

### 3. **Responsive Design**
- Adaptive navigation (BottomNav ↔ NavigationRail)
- Breakpoint-based layouts
- Responsive grids

---

## 🔄 **بازگردانی تغییرات (Rollback)**

### قبل از اعمال تغییرات:
```bash
git tag pre-uiux-backend-alignment
```

### بازگردانی کامل:
```bash
./scripts/rollback.sh

# یا دستی:
git reset --hard pre-uiux-backend-alignment
flutter clean && flutter pub get
```

---

## 📈 **Contract Tests مفصل**

### Test Coverage:
- ✅ **Request Format Validation**: Content-Type, headers, body structure
- ✅ **Response Parsing**: DTO serialization/deserialization
- ✅ **Error Handling**: Status codes, error envelope mapping
- ✅ **Authentication**: Token header format validation
- ✅ **Path Parameters**: URL construction verification

### Running Contract Tests:
```bash
# Specific API tests
flutter test test/api/auth_api_client_test.dart
flutter test test/api/category_api_client_test.dart

# All contract tests
flutter test test/api/
```

---

## 🛡️ **امنیت و کیفیت**

### 1. **API Security**:
- Token-based authentication مطابق backend
- Secure storage برای tokens
- Request/response validation

### 2. **Code Quality**:
- Strict null safety
- Linting rules
- Type-safe API calls
- Error boundary handling

### 3. **Performance**:
- Connection pooling
- Request caching
- Lazy loading
- Memory management

---

## 📊 **CI/CD Pipeline**

### GitHub Actions Workflow:
- ✅ **Code Analysis**: `flutter analyze`
- ✅ **Unit Tests**: `flutter test`
- ✅ **Contract Tests**: API client validation
- ✅ **Build Verification**: Multi-environment builds
- ✅ **Artifact Generation**: APKs + patches

### Pipeline Commands:
```bash
# Analysis
flutter analyze

# All tests
flutter test --coverage

# Contract tests
flutter test test/api/

# Build with environment
flutter build apk --dart-define=ENVIRONMENT=prod
```

---

## 🎯 **Verification Checklist**

### ✅ **Backend Alignment**:  
- [x] Authentication header format matches backend
- [x] Request/response envelopes match API contract
- [x] Error codes and messages aligned
- [x] Content-Type headers correct
- [x] Path parameters and query strings accurate

### ✅ **UI/UX Quality**:
- [x] Material 3 theming applied
- [x] Accessibility labels and focus management
- [x] Responsive layouts for all screen sizes
- [x] Performance optimizations applied
- [x] Dark mode support

### ✅ **Testing**:
- [x] Contract tests validate API integration
- [x] Widget tests cover UI components
- [x] Error handling tests comprehensive
- [x] All tests passing in CI

---

## � **Environment Configuration**

### Development:
```bash
export ENVIRONMENT=dev
export BASE_URL=https://api.asoud.ir  
export ENABLE_LOGS=true
export UIUX_PREVIEW=true
```

### Staging:
```bash
export ENVIRONMENT=staging
export BASE_URL=https://staging-api.asoud.ir
export ENABLE_LOGS=true
export UIUX_PREVIEW=false
```

### Production:
```bash
export ENVIRONMENT=prod
export BASE_URL=https://api.asoud.ir
export ENABLE_LOGS=false
export UIUX_PREVIEW=false
```

---

## 📞 **پشتیبانی و Troubleshooting**

### مشکلات رایج:

1. **Code Generation Errors**:
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

2. **API Authentication Issues**:
```bash
# بررسی format header
debugPrint('Auth Header: ${headers['Authorization']}');
# باید: "Token abc123..." باشد نه "Bearer abc123..."
```

3. **Build Failures**:
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

**نسخه:** 2.0.0+1 (Backend Aligned + UI/UX Enhanced)  
**تاریخ:** 4 آگوست 2025  
**وضعیت:** ✅ Ready for Production  
**Contract Compatibility:** ✅ Django Backend v1.8

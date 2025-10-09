# API Endpoint Fixes - Phase 0

## Issues Identified and Fixed

### 1. Inconsistent Bank API Endpoints

**Problem:** Mixed usage of `bank-info` vs `bank/info` in URLs
- Line 52: `user/bank-info/list/` (correct for getting available banks)
- Line 68: `user/bank/info/list/` (correct for getting user's bank cards)  
- Line 97: `user/bank/info/create/` (correct for creating bank cards)

**Solution:** Centralized all bank endpoints in Endpoints class with clear documentation

### 2. Hardcoded URLs Scattered Across Codebase

**Problem:** Direct string concatenation instead of centralized endpoint management

**Fixed Endpoints:**
- ✅ Bank information endpoints
- ✅ Product detail endpoints  
- ✅ Comment creation endpoints
- ✅ Inquiry endpoints
- ✅ Order management endpoints

### 3. Hardcoded Domain Names

**Problem:** `asoud.ir` hardcoded in multiple places, not environment-configurable

**Solution:** Added configurable base URLs:
- `API_BASE_URL` for API endpoints
- `ASSET_BASE_URL` for media/images  
- `WEBSITE_BASE_URL` for website links

### 4. Added Helper Methods

```dart
// Safe asset URL building
Endpoints.getAssetUrl(bank['logo'])  // Handles relative/absolute paths

// Website URL building
Endpoints.getWebsiteUrl()           // Main website
Endpoints.getWebsiteUrl('path')     // Specific page

// Store URL building  
Endpoints.getStoreUrl(storeLink)    // Store subdomains
```

## Files Modified

1. **lib/core/constants/endpoints.dart**
   - Added bank endpoints constants
   - Added comment/order/bookmark endpoints
   - Added configurable base URLs
   - Added URL helper methods

2. **lib/features/bank_card/screens/bank_card_list.dart**
   - Fixed inconsistent bank API endpoints
   - Used centralized Endpoints constants

3. **lib/features/product/screens/product_screen.dart** 
   - Replaced hardcoded product detail URL
   - Used centralized comment endpoint

4. **lib/features/inquiry/presentation/screens/inquiry_requests.dart**
   - Used centralized inquiry endpoint

## Security Benefits

1. **Centralized Configuration:** All URLs configurable via environment variables
2. **Consistent Endpoints:** Eliminates human error in API calls
3. **Environment Safety:** Different URLs for dev/staging/production
4. **Asset Security:** Proper URL validation in helper methods

## Breaking Changes Mitigation

- All changes are backward compatible
- Existing hardcoded URLs still work
- Gradual migration possible
- Helper methods handle edge cases

## Next Steps

1. ✅ **Immediate:** Critical inconsistencies fixed
2. **Phase 1:** Migrate remaining hardcoded URLs (25+ files)
3. **Phase 2:** Add URL validation and error handling
4. **Phase 3:** Implement endpoint versioning support

## Testing Required

```bash
# Test API connectivity
flutter test test/core/network/
  
# Test endpoint constants
flutter test test/core/constants/

# Integration test bank endpoints
flutter test test/features/bank_card/

# Test asset URL building
flutter test test/core/helpers/
```

## Environment Configuration

Add to your environment or build configuration:

```bash
# Production
API_BASE_URL=https://api.asoud.ir/api/v1/
ASSET_BASE_URL=https://asoud.ir/
WEBSITE_BASE_URL=https://asoud.ir/

# Development  
API_BASE_URL=http://localhost:8000/api/v1/
ASSET_BASE_URL=http://localhost:8000/
WEBSITE_BASE_URL=http://localhost:3000/
```

## Impact Assessment

- **Risk Level:** Low (backward compatible)
- **Testing Required:** Medium (endpoint validation)
- **Performance Impact:** Minimal improvement
- **Security Impact:** High improvement (configurable environments)
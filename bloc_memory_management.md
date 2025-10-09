# BLoC Memory Leak Prevention Guide

## Problem Solved

**Memory Leak Issue:** All BLoCs were registered globally in `main.dart` using `MultiBlocProvider`, causing them to persist throughout the entire app lifecycle even when not needed.

**Solution:** Implemented scoped BLoC management that creates BLoCs only when needed and automatically disposes them when the scope is destroyed.

## Changes Made

### 1. Migrated Critical BLoCs to BaseBloc

✅ **Migrated BLoCs** (now have automatic subscription cleanup):
- `AuthBloc` → extends `BaseBloc` ✅
- `VendorBloc` → extends `BaseBloc` ✅  
- `MarketBloc` → extends `BaseBloc` ✅
- `WorkspaceBloc` → extends `BaseBloc` ✅
- `AddProductBloc` → extends `BaseBloc` ✅
- `CommentBloc` → extends `BaseBloc` ✅
- `ThemeBloc` → extends `BaseBloc` ✅
- `BusinessBloc` → extends `BaseBloc` ✅

⚠️ **Remaining BLoCs** (need migration):
- `CreateWorkSpaceBloc`
- `JobmanagmentBloc` 
- `SplashBloc`
- `PaymentBloc`
- `ProductBloc`
- `ServiceBloc`
- `ReservationBloc`
- `NotificationBloc`
- `ProfileBloc`
- `CustomerBloc`
- `ChatBloc`
- `InquiryBloc`
- `CartBloc`

### 2. Reduced Global BLoC Registration

**Before:**
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => ServiceLocator.get<SplashBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<AuthBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<CreateWorkSpaceBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<JobmanagmentBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<VendorBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<WorkspaceBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<AddProductBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<ThemeBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<CommentBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<MarketBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<BusinessBloc>()),
  ],
  // ...
```

**After:**
```dart
MultiBlocProvider(
  providers: [
    // Only essential app-level BLoCs that need to persist throughout app lifecycle
    BlocProvider(create: (context) => ServiceLocator.get<SplashBloc>()),
    BlocProvider(create: (context) => ServiceLocator.get<AuthBloc>()),
    // Other BLoCs should be provided at page/feature level using BlocScope
  ],
  // ...
```

### 3. Created BlocScope Management System

**File:** `lib/core/bloc/bloc_scope.dart`

**Key Features:**
- Automatic BLoC disposal when widget is removed
- Page-level BLoC providers
- Conditional BLoC creation
- Factory helpers for common BLoC combinations
- Extension methods for easy usage

## How to Use BlocScope

### 1. Single BLoC for a Screen

**Old way (causes memory leaks):**
```dart
class VendorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BLoC is already globally available but never disposed
    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, state) => Container(),
    );
  }
}
```

**New way (proper disposal):**
```dart
class VendorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocScope<VendorBloc>(
      create: () => ServiceLocator.get<VendorBloc>(),
      child: BlocBuilder<VendorBloc, VendorState>(
        builder: (context, state) => Container(),
      ),
    );
  }
}
```

### 2. Multiple BLoCs for a Screen

```dart
class MarketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocScope(
      providers: BlocFactories.market(), // Provides MarketBloc, AddProductBloc, ThemeBloc
      child: Column(
        children: [
          BlocBuilder<MarketBloc, MarketState>(
            builder: (context, state) => MarketList(),
          ),
          BlocBuilder<AddProductBloc, AddProductState>(
            builder: (context, state) => AddProductForm(),
          ),
        ],
      ),
    );
  }
}
```

### 3. Using Extension Methods

```dart
class VendorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container()
      .withBloc<VendorBloc>(() => ServiceLocator.get<VendorBloc>());
  }
}
```

### 4. Page-Level BLoC Provider

```dart
class ProductDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageBlocProvider<ProductBloc>(
      create: () => ServiceLocator.get<ProductBloc>(),
      builder: (context, productBloc) {
        // BLoC is automatically disposed when screen is popped
        return BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) => ProductDetail(state: state),
        );
      },
    );
  }
}
```

## Implementation Strategy

### Phase 1: Essential Screen Migration (PRIORITY)
Migrate screens that are frequently opened/closed:

1. **VendorScreen** - Uses `VendorBloc`, `WorkspaceBloc`
2. **MarketDetailScreen** - Uses `MarketBloc`, `AddProductBloc`
3. **ProductDetailScreen** - Uses `ProductBloc`, `CommentBloc`
4. **BusinessCardScreen** - Uses `BusinessBloc`

### Phase 2: Remaining BLoC Migration
Continue migrating remaining BLoCs to extend `BaseBloc`:

```bash
# Use the migration script
./migrate_blocs.sh

# Verify migration
./verify_bloc_migration.sh
```

### Phase 3: Remove Global Dependencies
Update screens to not rely on global BLoC providers:

1. Find usages: `grep -r "BlocProvider.of" lib/`
2. Replace with scoped providers
3. Test memory usage

## Migration Script Usage

```bash
# Make script executable
chmod +x migrate_blocs.sh

# Run migration
./migrate_blocs.sh

# Verify results
./verify_bloc_migration.sh

# Test the app
flutter run --profile
```

## Testing Memory Improvements

### Before Changes
- All 11+ BLoCs persist in memory throughout app lifecycle
- Memory usage grows continuously
- No automatic cleanup of subscriptions

### After Changes
- Only 2 essential BLoCs persist globally (SplashBloc, AuthBloc)
- Feature BLoCs created/disposed as needed
- Automatic subscription cleanup via BaseBloc
- Memory usage stable

### Memory Profiling

```bash
# Profile memory usage
flutter run --profile

# Use Flutter Inspector to monitor:
# 1. Widget tree (check for disposed BLoCs)
# 2. Memory usage (should be more stable)
# 3. Performance overlay (should show improvements)
```

## Breaking Changes

**❌ Breaking:** Screens that depend on global BLoCs without scoping will break
**✅ Solution:** Wrap screens with appropriate BlocScope

**❌ Breaking:** Direct BlocProvider.of<T> calls may fail if BLoC not in scope
**✅ Solution:** Use context.read<T>() and ensure proper scoping

## Benefits

1. **Memory Efficiency:** BLoCs disposed when not needed
2. **Better Architecture:** Clear BLoC lifecycle management  
3. **Improved Performance:** Reduced memory pressure
4. **Debugging:** Easier to track BLoC lifetimes
5. **Scalability:** Pattern scales with app complexity

## Monitoring

Add logging to BaseBloc to monitor creation/disposal:

```dart
// In BaseBloc constructor
logInfo('BLoC Created: ${runtimeType}');

// In BaseBloc close()
logInfo('BLoC Disposed: ${runtimeType}');
```

This will help verify that BLoCs are being properly created and disposed.
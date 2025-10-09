import 'package:asood/core/architecture/result.dart';

/// Base state class for all BLoC states
/// 
/// Provides common state patterns and ensures consistency
/// across all features in the application.
/// 
/// [T] is the type of data this state holds
abstract class BaseBlocState<T> {
  /// Current status of the state
  final StateStatus status;
  
  /// Data held by this state (null when loading or error)
  final T? data;
  
  /// Error information when status is failure
  final ResultError? error;
  
  /// Additional message for user feedback
  final String? message;
  
  /// Timestamp when this state was created
  final DateTime timestamp;

  const BaseBlocState({
    required this.status,
    this.data,
    this.error,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convenience getters for common state checks
  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isFailure => status == StateStatus.failure;
  bool get isInitial => status == StateStatus.initial;
  
  /// Check if state has data
  bool get hasData => data != null;
  
  /// Check if state has error
  bool get hasError => error != null;
  
  /// Get user-friendly error message
  String? get errorMessage {
    if (error == null) return null;
    return error!.message;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BaseBlocState<T> &&
           other.status == status &&
           other.data == data &&
           other.error == error &&
           other.message == message;
  }

  @override
  int get hashCode => Object.hash(status, data, error, message);

  @override
  String toString() {
    return '${runtimeType}(status: $status, hasData: $hasData, hasError: $hasError)';
  }
}

/// Enumeration of possible state statuses
enum StateStatus {
  /// Initial state when BLoC is first created
  initial,
  
  /// Loading state during async operations
  loading,
  
  /// Success state when operation completed successfully
  success,
  
  /// Failure state when operation failed
  failure;

  /// Check if status indicates an active operation
  bool get isActive => this == StateStatus.loading;
  
  /// Check if status indicates completion (success or failure)
  bool get isComplete => this == StateStatus.success || this == StateStatus.failure;
}

/// Mixin for states that need pagination support
mixin PaginationMixin<T> on BaseBlocState<List<T>> {
  /// Current page number (0-based)
  int get currentPage;
  
  /// Whether there are more pages to load
  bool get hasMorePages;
  
  /// Total number of items (if known)
  int? get totalCount;
  
  /// Whether currently loading more items
  bool get isLoadingMore;

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 0;
  
  /// Check if pagination is supported
  bool get supportsPagination => true;
}

/// Mixin for states that need refresh support
mixin RefreshMixin<T> on BaseBlocState<T> {
  /// Whether currently refreshing
  bool get isRefreshing;
  
  /// Last refresh timestamp
  DateTime? get lastRefreshTime;
  
  /// Check if refresh is available
  bool get canRefresh => !isLoading && !isRefreshing;
}

/// Mixin for states that cache data
mixin CacheMixin<T> on BaseBlocState<T> {
  /// Whether data is from cache
  bool get isFromCache;
  
  /// Cache expiry time
  DateTime? get cacheExpiryTime;
  
  /// Check if cached data is still valid
  bool get isCacheValid {
    if (cacheExpiryTime == null) return false;
    return DateTime.now().isBefore(cacheExpiryTime!);
  }
}

/// Generic data state for simple data holding
class DataState<T> extends BaseBlocState<T> {
  const DataState({
    required super.status,
    super.data,
    super.error,
    super.message,
    super.timestamp,
  });

  /// Create initial state
  factory DataState.initial() {
    return const DataState(status: StateStatus.initial);
  }

  /// Create loading state
  factory DataState.loading({String? message}) {
    return DataState(
      status: StateStatus.loading,
      message: message,
    );
  }

  /// Create success state with data
  factory DataState.success(T data, {String? message}) {
    return DataState(
      status: StateStatus.success,
      data: data,
      message: message,
    );
  }

  /// Create failure state with error
  factory DataState.failure(ResultError error, {String? message}) {
    return DataState(
      status: StateStatus.failure,
      error: error,
      message: message,
    );
  }

  /// Create a copy with updated fields
  DataState<T> copyWith({
    StateStatus? status,
    T? data,
    ResultError? error,
    String? message,
    DateTime? timestamp,
  }) {
    return DataState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// List state for managing lists of items with pagination
class ListState<T> extends BaseBlocState<List<T>> with PaginationMixin<T> {
  @override
  final int currentPage;
  
  @override
  final bool hasMorePages;
  
  @override
  final int? totalCount;
  
  @override
  final bool isLoadingMore;

  const ListState({
    required super.status,
    super.data,
    super.error,
    super.message,
    super.timestamp,
    this.currentPage = 0,
    this.hasMorePages = false,
    this.totalCount,
    this.isLoadingMore = false,
  });

  /// Create initial list state
  factory ListState.initial() {
    return const ListState(
      status: StateStatus.initial,
      data: [],
    );
  }

  /// Create loading state
  factory ListState.loading({bool isLoadingMore = false}) {
    return ListState(
      status: StateStatus.loading,
      data: const [],
      isLoadingMore: isLoadingMore,
    );
  }

  /// Create success state with data
  factory ListState.success(
    List<T> data, {
    int currentPage = 0,
    bool hasMorePages = false,
    int? totalCount,
    String? message,
  }) {
    return ListState(
      status: StateStatus.success,
      data: data,
      currentPage: currentPage,
      hasMorePages: hasMorePages,
      totalCount: totalCount,
      message: message,
    );
  }

  /// Create failure state
  factory ListState.failure(ResultError error, {String? message}) {
    return ListState(
      status: StateStatus.failure,
      data: const [],
      error: error,
      message: message,
    );
  }

  /// Create a copy with updated fields
  ListState<T> copyWith({
    StateStatus? status,
    List<T>? data,
    ResultError? error,
    String? message,
    DateTime? timestamp,
    int? currentPage,
    bool? hasMorePages,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return ListState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  /// Add more items (for pagination)
  ListState<T> addMoreItems(
    List<T> newItems, {
    bool? hasMorePages,
    int? totalCount,
  }) {
    final updatedData = [...(data ?? []), ...newItems];
    
    return copyWith(
      status: StateStatus.success,
      data: updatedData,
      currentPage: currentPage + 1,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: false,
    );
  }

  /// Set loading more state
  ListState<T> setLoadingMore() {
    return copyWith(isLoadingMore: true);
  }
}
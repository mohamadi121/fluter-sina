import 'package:asood/core/architecture/result.dart';

/// Base class for all use cases in the application
/// 
/// Use cases represent business logic operations and should be:
/// - Stateless
/// - Single responsibility
/// - Independent of external frameworks
/// - Testable
/// 
/// Type parameters:
/// - [Type]: The return type of the use case
/// - [Params]: The parameters required for the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters
  Future<Result<Type>> call(Params params);
}

/// Use case that doesn't require any parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Result<Type>> call();
}

/// Synchronous use case for operations that don't require async
abstract class SyncUseCase<Type, Params> {
  /// Execute the use case synchronously
  Result<Type> call(Params params);
}

/// Synchronous use case without parameters
abstract class NoParamsSyncUseCase<Type> {
  /// Execute the use case synchronously without parameters
  Result<Type> call();
}

/// Stream-based use case for reactive operations
abstract class StreamUseCase<Type, Params> {
  /// Execute the use case and return a stream
  Stream<Result<Type>> call(Params params);
}

/// Stream use case without parameters
abstract class NoParamsStreamUseCase<Type> {
  /// Execute the use case and return a stream without parameters
  Stream<Result<Type>> call();
}

/// Base class for use case parameters
/// 
/// All use case parameters should extend this class for consistency
abstract class UseCaseParams {
  const UseCaseParams();
  
  /// Convert parameters to a list for equality comparison
  List<Object?> get props;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UseCaseParams) return false;
    
    final listEquals = (List<Object?> a, List<Object?> b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    };
    
    return listEquals(props, other.props);
  }
  
  @override
  int get hashCode => Object.hashAll(props);
  
  @override
  String toString() => '${runtimeType}(${props.join(', ')})';
}

/// Empty parameters for use cases that don't need parameters
class NoParams extends UseCaseParams {
  const NoParams();
  
  @override
  List<Object?> get props => [];
}

/// Example of how to create a use case:
/// 
/// ```dart
/// class SendOtpUseCase implements UseCase<void, SendOtpParams> {
///   final AuthRepository _repository;
///   
///   SendOtpUseCase(this._repository);
///   
///   @override
///   Future<Result<void>> call(SendOtpParams params) async {
///     // Validate business rules
///     if (!_isValidPhoneNumber(params.phoneNumber)) {
///       return const Failure(ValidationError('Invalid phone number format'));
///     }
///     
///     // Call repository
///     return await _repository.sendOtp(params.phoneNumber);
///   }
///   
///   bool _isValidPhoneNumber(String phone) {
///     return RegExp(r'^09\d{9}$').hasMatch(phone);
///   }
/// }
/// 
/// class SendOtpParams extends UseCaseParams {
///   final String phoneNumber;
///   
///   const SendOtpParams({required this.phoneNumber});
///   
///   @override
///   List<Object?> get props => [phoneNumber];
/// }
/// ```
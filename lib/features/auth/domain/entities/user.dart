/// Domain entity representing a user in the system
/// 
/// This is a pure domain model that contains only business logic
/// and has no dependencies on external frameworks or data sources.
class User {
  final String id;
  final String phoneNumber;
  final bool isVerified;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final UserStatus status;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.isVerified,
    this.firstName,
    this.lastName,
    this.email,
    this.createdAt,
    this.lastLoginAt,
    this.status = UserStatus.active,
  });

  /// Get user's full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return phoneNumber;
  }

  /// Get display name for UI
  String get displayName => fullName.isNotEmpty ? fullName : phoneNumber;

  /// Check if user profile is complete
  bool get isProfileComplete {
    return firstName != null && 
           lastName != null && 
           email != null;
  }

  /// Check if user can perform actions
  bool get canPerformActions {
    return isVerified && status == UserStatus.active;
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? phoneNumber,
    bool? isVerified,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserStatus? status,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
           other.id == id &&
           other.phoneNumber == phoneNumber &&
           other.isVerified == isVerified &&
           other.firstName == firstName &&
           other.lastName == lastName &&
           other.email == email &&
           other.createdAt == createdAt &&
           other.lastLoginAt == lastLoginAt &&
           other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      phoneNumber,
      isVerified,
      firstName,
      lastName,
      email,
      createdAt,
      lastLoginAt,
      status,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, phoneNumber: $phoneNumber, fullName: $fullName, isVerified: $isVerified, status: $status)';
  }
}

/// User status enumeration
enum UserStatus {
  /// User is active and can use the application
  active,
  
  /// User is temporarily suspended
  suspended,
  
  /// User account is permanently banned
  banned,
  
  /// User account is pending verification
  pending,
  
  /// User account is inactive (deactivated by user)
  inactive;

  /// Check if user status allows application usage
  bool get isUsable => this == UserStatus.active;

  /// Get user-friendly status description
  String get description {
    switch (this) {
      case UserStatus.active:
        return 'فعال';
      case UserStatus.suspended:
        return 'معلق';
      case UserStatus.banned:
        return 'مسدود';
      case UserStatus.pending:
        return 'در انتظار تایید';
      case UserStatus.inactive:
        return 'غیرفعال';
    }
  }
}
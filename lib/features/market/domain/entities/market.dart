/// Domain entity representing a market/store in the system
/// 
/// This is a pure domain model representing the core business concept
/// of a market without any external dependencies.
class Market {
  final String id;
  final String businessId;
  final String name;
  final String description;
  final String? slogan;
  final String categoryId;
  final String subCategoryId;
  final MarketType type;
  final MarketStatus status;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MarketContact? contact;
  final MarketLocation? location;
  final List<String> imageUrls;
  final String? logoUrl;
  final String? backgroundUrl;
  final MarketTheme? theme;
  final MarketSettings settings;

  const Market({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    this.slogan,
    required this.categoryId,
    required this.subCategoryId,
    required this.type,
    required this.status,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
    this.contact,
    this.location,
    this.imageUrls = const [],
    this.logoUrl,
    this.backgroundUrl,
    this.theme,
    this.settings = const MarketSettings(),
  });

  /// Get market's display name with fallback
  String get displayName => name.isNotEmpty ? name : businessId;

  /// Check if market is active and accepting orders
  bool get isActive => status == MarketStatus.active;

  /// Check if market can be discovered by users
  bool get isDiscoverable => status.isDiscoverable;

  /// Check if market has complete profile
  bool get hasCompleteProfile {
    return name.isNotEmpty &&
           description.isNotEmpty &&
           contact != null &&
           location != null;
  }

  /// Check if market has visual branding
  bool get hasBranding => logoUrl != null && backgroundUrl != null;

  /// Get market's public URL
  String get publicUrl => 'https://asoud.ir/$businessId';

  /// Create a copy with updated fields
  Market copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    String? slogan,
    String? categoryId,
    String? subCategoryId,
    MarketType? type,
    MarketStatus? status,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    MarketContact? contact,
    MarketLocation? location,
    List<String>? imageUrls,
    String? logoUrl,
    String? backgroundUrl,
    MarketTheme? theme,
    MarketSettings? settings,
  }) {
    return Market(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      slogan: slogan ?? this.slogan,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      type: type ?? this.type,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contact: contact ?? this.contact,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      logoUrl: logoUrl ?? this.logoUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      theme: theme ?? this.theme,
      settings: settings ?? this.settings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Market &&
           other.id == id &&
           other.businessId == businessId &&
           other.name == name &&
           other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, businessId, name, status);

  @override
  String toString() => 'Market(id: $id, businessId: $businessId, name: $name, status: $status)';
}

/// Market contact information
class MarketContact {
  final String? phoneNumber;
  final String? mobileNumber;
  final String? faxNumber;
  final String? email;
  final String? website;
  final String? telegramId;
  final String? instagramId;

  const MarketContact({
    this.phoneNumber,
    this.mobileNumber,
    this.faxNumber,
    this.email,
    this.website,
    this.telegramId,
    this.instagramId,
  });

  /// Check if any contact method is available
  bool get hasAnyContact {
    return phoneNumber != null ||
           mobileNumber != null ||
           email != null ||
           website != null;
  }

  /// Get primary contact method
  String? get primaryContact => mobileNumber ?? phoneNumber ?? email;

  MarketContact copyWith({
    String? phoneNumber,
    String? mobileNumber,
    String? faxNumber,
    String? email,
    String? website,
    String? telegramId,
    String? instagramId,
  }) {
    return MarketContact(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      faxNumber: faxNumber ?? this.faxNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      telegramId: telegramId ?? this.telegramId,
      instagramId: instagramId ?? this.instagramId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MarketContact &&
           other.phoneNumber == phoneNumber &&
           other.mobileNumber == mobileNumber &&
           other.email == email;
  }

  @override
  int get hashCode => Object.hash(phoneNumber, mobileNumber, email);
}

/// Market location information
class MarketLocation {
  final String? countryId;
  final String? provinceId;
  final String? cityId;
  final String? address;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  const MarketLocation({
    this.countryId,
    this.provinceId,
    this.cityId,
    this.address,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  /// Check if location has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Check if location has complete address
  bool get hasCompleteAddress {
    return countryId != null &&
           provinceId != null &&
           cityId != null &&
           address != null;
  }

  MarketLocation copyWith({
    String? countryId,
    String? provinceId,
    String? cityId,
    String? address,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) {
    return MarketLocation(
      countryId: countryId ?? this.countryId,
      provinceId: provinceId ?? this.provinceId,
      cityId: cityId ?? this.cityId,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MarketLocation &&
           other.latitude == latitude &&
           other.longitude == longitude &&
           other.address == address;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, address);
}

/// Market theme/appearance settings
class MarketTheme {
  final String? primaryColor;
  final String? secondaryColor;
  final String? backgroundColor;
  final String? textColor;
  final int? templateId;

  const MarketTheme({
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.textColor,
    this.templateId,
  });

  MarketTheme copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? textColor,
    int? templateId,
  }) {
    return MarketTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      templateId: templateId ?? this.templateId,
    );
  }
}

/// Market operational settings
class MarketSettings {
  final bool isOrderEnabled;
  final bool isDeliveryEnabled;
  final bool isPickupEnabled;
  final double? minimumOrderAmount;
  final double? deliveryFee;
  final int? deliveryTimeMinutes;

  const MarketSettings({
    this.isOrderEnabled = true,
    this.isDeliveryEnabled = false,
    this.isPickupEnabled = true,
    this.minimumOrderAmount,
    this.deliveryFee,
    this.deliveryTimeMinutes,
  });

  MarketSettings copyWith({
    bool? isOrderEnabled,
    bool? isDeliveryEnabled,
    bool? isPickupEnabled,
    double? minimumOrderAmount,
    double? deliveryFee,
    int? deliveryTimeMinutes,
  }) {
    return MarketSettings(
      isOrderEnabled: isOrderEnabled ?? this.isOrderEnabled,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      isPickupEnabled: isPickupEnabled ?? this.isPickupEnabled,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
    );
  }
}

/// Market type enumeration
enum MarketType {
  online,
  physical,
  hybrid;

  String get description {
    switch (this) {
      case MarketType.online:
        return 'آنلاین';
      case MarketType.physical:
        return 'فیزیکی';
      case MarketType.hybrid:
        return 'ترکیبی';
    }
  }
}

/// Market status enumeration
enum MarketStatus {
  /// Market is active and operational
  active,
  
  /// Market is temporarily inactive
  inactive,
  
  /// Market is in queue for approval
  pending,
  
  /// Market is suspended
  suspended,
  
  /// Market is permanently closed
  closed;

  /// Check if market can be discovered by users
  bool get isDiscoverable => this == MarketStatus.active;

  /// Check if market can accept orders
  bool get canAcceptOrders => this == MarketStatus.active;

  String get description {
    switch (this) {
      case MarketStatus.active:
        return 'فعال';
      case MarketStatus.inactive:
        return 'غیرفعال';
      case MarketStatus.pending:
        return 'در انتظار تایید';
      case MarketStatus.suspended:
        return 'معلق';
      case MarketStatus.closed:
        return 'بسته';
    }
  }
}
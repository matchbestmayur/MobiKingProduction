// models/coupon_model.dart
class CouponModel {
  final String id;
  final String code;
  final String value;
  final String percent;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  CouponModel({
    required this.id,
    required this.code,
    required this.value,
    required this.percent,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  // ✅ FIXED: Factory constructor with proper error handling
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      value: json['value']?.toString() ?? '0',
      percent: json['percent']?.toString() ?? '0',
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate']) ?? DateTime.now().add(Duration(days: 30)),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      version: json['__v'] is int ? json['__v'] : int.tryParse(json['__v']?.toString() ?? '0') ?? 0,
    );
  }

  // ✅ HELPER: Safe DateTime parsing
  // In your CouponModel - update the _parseDateTime method
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is DateTime) {
        // ✅ Already a DateTime object, return as-is
        return dateValue;
      } else if (dateValue is String) {
        if (dateValue.isEmpty) return null;
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        // Handle timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        print('Unknown date type: ${dateValue.runtimeType} - Value: $dateValue');
        return null;
      }
    } catch (e) {
      print('Error parsing date: $dateValue (${dateValue.runtimeType}) - $e');
      return null;
    }
  }

  // Convert CouponModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'value': value,
      'percent': percent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  // ✅ FIXED: Check if coupon is currently valid with null safety
  bool get isValid {
    try {
      final now = DateTime.now();
      return now.isAfter(startDate) && now.isBefore(endDate);
    } catch (e) {
      print('Error checking coupon validity: $e');
      return false;
    }
  }

  // ✅ FIXED: Get discount amount as double with better parsing
  double get discountValue {
    try {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    } catch (e) {
      print('Error parsing discount value: $e');
      return 0.0;
    }
  }

  // ✅ FIXED: Get discount percentage as double with better parsing
  double get discountPercent {
    try {
      if (percent.isEmpty) return 0.0;
      return double.tryParse(percent.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    } catch (e) {
      print('Error parsing discount percent: $e');
      return 0.0;
    }
  }

  // ✅ FIXED: Check if coupon is expired with error handling
  bool get isExpired {
    try {
      return DateTime.now().isAfter(endDate);
    } catch (e) {
      print('Error checking if coupon is expired: $e');
      return true; // Assume expired on error
    }
  }

  // ✅ FIXED: Check if coupon is not yet active with error handling
  bool get isNotYetActive {
    try {
      return DateTime.now().isBefore(startDate);
    } catch (e) {
      print('Error checking if coupon is not yet active: $e');
      return false; // Assume active on error
    }
  }

  // ✅ ADDED: Helper method to check if coupon has any discount
  bool get hasDiscount {
    return discountValue > 0 || discountPercent > 0;
  }

  // ✅ ADDED: Get formatted discount text
  String get formattedDiscount {
    if (discountPercent > 0) {
      return '${discountPercent.toInt()}% OFF';
    } else if (discountValue > 0) {
      return '₹${discountValue.toInt()} OFF';
    }
    return 'DISCOUNT';
  }

  @override
  String toString() {
    return 'CouponModel(id: $id, code: $code, value: $value, percent: $percent, isValid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ✅ FIXED: Response wrapper for API responses
class CouponResponse {
  final int statusCode;
  final CouponModel? data;
  final String message;
  final bool success;

  CouponResponse({
    required this.statusCode,
    this.data,
    required this.message,
    required this.success,
  });

  factory CouponResponse.fromJson(Map<String, dynamic> json) {
    CouponModel? couponData;

    try {
      if (json['data'] != null && json['data'] is Map<String, dynamic>) {
        couponData = CouponModel.fromJson(json['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error parsing coupon data: $e');
      couponData = null;
    }

    return CouponResponse(
      statusCode: json['statusCode'] is int
          ? json['statusCode']
          : int.tryParse(json['statusCode']?.toString() ?? '0') ?? 0,
      data: couponData,
      message: json['message']?.toString() ?? '',
      success: json['success'] == true || json['success']?.toString().toLowerCase() == 'true',
    );
  }
}

// ✅ FIXED: List response for multiple coupons
class CouponListResponse {
  final int statusCode;
  final List<CouponModel> data;
  final String message;
  final bool success;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  CouponListResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory CouponListResponse.fromJson(Map<String, dynamic> json) {
    List<CouponModel> coupons = [];

    try {
      if (json['data'] != null) {
        if (json['data'] is List) {
          for (var couponJson in json['data'] as List) {
            try {
              if (couponJson is Map<String, dynamic>) {
                final coupon = CouponModel.fromJson(couponJson);
                coupons.add(coupon);
              }
            } catch (e) {
              print('Error parsing individual coupon: $e');
              // Skip this coupon but continue with others
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing coupons list: $e');
    }

    return CouponListResponse(
      statusCode: json['statusCode'] is int
          ? json['statusCode']
          : int.tryParse(json['statusCode']?.toString() ?? '0') ?? 0,
      data: coupons,
      message: json['message']?.toString() ?? '',
      success: json['success'] == true || json['success']?.toString().toLowerCase() == 'true',
      totalCount: json['totalCount'] is int
          ? json['totalCount']
          : int.tryParse(json['totalCount']?.toString() ?? '0'),
      currentPage: json['currentPage'] is int
          ? json['currentPage']
          : int.tryParse(json['currentPage']?.toString() ?? '1'),
      totalPages: json['totalPages'] is int
          ? json['totalPages']
          : int.tryParse(json['totalPages']?.toString() ?? '1'),
    );
  }
}

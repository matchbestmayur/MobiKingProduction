// lib/app/data/product_model.dart

// Assuming SellingPrice and ProductModel are defined here,
// or defined globally if used elsewhere and not part of this file.
// If SellingPrice is not defined, you'll need to define it as below:
import 'package:mobiking/app/data/scan_model.dart';

class SellingPrice {
  final String id;
  final String variantName;
  final double price;
  final int quantity;

  SellingPrice({required this.id, required this.variantName, required this.price, required this.quantity});

  factory SellingPrice.fromJson(Map<String, dynamic> json) {
    return SellingPrice(
      id: json['_id'] ?? '',
      variantName: json['variantName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'variantName': variantName,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderItemProductModel {
  final String id;
  final String name;
  final String fullName;
  final String slug;
  final String description;
  final bool active;
  final bool newArrival;
  final bool liked;
  final bool bestSeller;
  final bool recommended;
  final List<SellingPrice> sellingPrice;
  final String categoryId; // This will store the _id of the category
  final List<String> images;
  final int totalStock;
  final List<String> stockIds;
  final List<String> orderIds;
  final List<String> groupIds;
  final Map<String, int> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v; // "__v" field

  OrderItemProductModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.slug,
    required this.description,
    required this.active,
    required this.newArrival,
    required this.liked,
    required this.bestSeller,
    required this.recommended,
    required this.sellingPrice,
    required this.categoryId,
    required this.images,
    required this.totalStock,
    required this.stockIds,
    required this.orderIds,
    required this.groupIds,
    required this.variants,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory OrderItemProductModel.fromJson(Map<String, dynamic> json) {
    return OrderItemProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      fullName: json['fullName'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      newArrival: json['newArrival'] ?? false,
      liked: json['liked'] ?? false,
      bestSeller: json['bestSeller'] ?? false,
      recommended: json['recommended'] ?? false,
      sellingPrice: (json['sellingPrice'] as List<dynamic>?)
          ?.map((e) => SellingPrice.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      // Handle category which can be an object or just an ID string
      categoryId: (json['category'] is Map && json['category'] != null)
          ? json['category']['_id'] as String? ?? ''
          : (json['category'] is String ? json['category'] as String : ''),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
      stockIds: (json['stock'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      orderIds: (json['orders'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      groupIds: (json['groups'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      variants: Map<String, int>.from(json['variants'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'fullName': fullName,
      'slug': slug,
      'description': description,
      'active': active,
      'newArrival': newArrival,
      'liked': liked,
      'bestSeller': bestSeller,
      'recommended': recommended,
      'sellingPrice': sellingPrice.map((e) => e.toJson()).toList(),
      'category': categoryId, // Sending back just the ID
      'images': images,
      'totalStock': totalStock,
      'stock': stockIds,
      'orders': orderIds,
      'groups': groupIds,
      'variants': variants,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}

class OrderItemModel {
  final String id; // Added _id for the order item itself
  final OrderItemProductModel? productDetails; // Changed name for clarity, made nullable
  final String variantName;
  final int quantity;
  final double price; // Changed to double as prices often have decimals

  OrderItemModel({
    required this.id,
    this.productDetails,
    required this.variantName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['_id'] as String? ?? '', // Parse the _id of the item in the array
      productDetails: json['productId'] != null && json['productId'] is Map<String, dynamic>
          ? OrderItemProductModel.fromJson(json['productId'] as Map<String, dynamic>)
          : null, // Correctly parse nested product details if populated
      variantName: json['variantName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // Safely parse to double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Include _id when converting to JSON
      'productId': productDetails?.toJson(), // Use productDetails.toJson()
      'variantName': variantName,
      'quantity': quantity,
      'price': price,
    };
  }
}

// You might need a simple User model for userId if you want to parse it fully
class OrderUserModel {
  final String id;
  final String? email;
  final String? phoneNo;
  // ... other fields if needed from userId object

  OrderUserModel({
    required this.id,
    this.email,
    this.phoneNo,
    // ...
  });

  factory OrderUserModel.fromJson(Map<String, dynamic> json) {
    return OrderUserModel(
      id: json['_id'] as String? ?? '',
      email: json['email'] as String?,
      phoneNo: json['phoneNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phoneNo': phoneNo,
    };
  }
}

// Helper function to parse numeric values which might come as String or num
double _parseNum(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0; // Fallback for unexpected types
}

// Represents a request (Cancel, Warranty, Return) associated with an order.
// This is moved here from request_model.dart as it's part of the order details.
class RequestModel {
  final String? id; // Mongoose _id for the subdocument
  final String type;
  final bool isRaised;
  final DateTime? raisedAt; // Use DateTime for timestamps
  final bool isResolved;
  final String status;
  final DateTime? resolvedAt; // Use DateTime for timestamps
  final String? reason; // Reason for the request

  // Timestamps from Mongoose: createdAt and updatedAt
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RequestModel({
    this.id,
    required this.type,
    this.isRaised = false,
    this.raisedAt,
    this.isResolved = false,
    this.status = "Pending",
    this.resolvedAt,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a RequestModel from a JSON map.
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['_id'] as String?,
      type: json['type'] as String? ?? 'Unknown',
      isRaised: json['isRaised'] as bool? ?? false,
      raisedAt: DateTime.tryParse(json['raisedAt'] as String? ?? ''),
      isResolved: json['isResolved'] as bool? ?? false,
      status: json['status'] as String? ?? 'Pending',
      resolvedAt: DateTime.tryParse(json['resolvedAt'] as String? ?? ''),
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  /// Converts a RequestModel instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'isRaised': isRaised,
      'raisedAt': raisedAt?.toIso8601String(),
      'isResolved': isResolved,
      'status': status,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'reason': reason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class OrderModel {
  final String id; // This is the MongoDB _id
  final String orderId; // This is the human-readable order ID like "842BABB1"

  // Core Order States
  final String status; // Main order status
  final String? holdReason;
  final String shippingStatus; // Shipping status
  final List<Scan>? scans;
  final String paymentStatus;

  // Shiprocket Fields
  final String? shipmentId;
  final String? shiprocketOrderId;
  final String? shiprocketChannelId;
  final String? awbCode;
  final String? courierName;
  final DateTime? courierAssignedAt;
  final bool pickupScheduled;
  final String? pickupTokenNumber;
  final String? pickupDate;
  final String? expectedDeliveryDate;
  final String? pickupSlot;
  final String? shippingLabelUrl;
  final String? shippingManifestUrl;
  final String? deliveredAt;

  // Payment Fields
  final String? razorpayOrderId;
  final String? razorpayPaymentId;

  // Order Requests
  final List<RequestModel> requests;

  // Order Metadata
  final String type;
  final String method;
  final bool isAppOrder;
  final bool abondonedOrder;

  // Pricing
  final double orderAmount;
  final double deliveryCharge;
  final double discount;
  final String? gst;
  final double? subtotal;

  // Customer Info
  final String? name;
  final String? email;
  final String? phoneNo;

  // Address
  final String? address;
  final String? addressId;

  // Relations
  final OrderUserModel? userId;
  final List<OrderItemModel> items;

  // Timestamps from Mongoose
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? v;

  OrderModel({
    required this.id, // MongoDB _id
    required this.orderId, // Human-readable orderId
    required this.status,
    this.holdReason,
    required this.shippingStatus,
    this.scans,
    required this.paymentStatus,
    this.shipmentId,
    this.shiprocketOrderId,
    this.shiprocketChannelId,
    this.awbCode,
    this.courierName,
    this.courierAssignedAt,
    this.pickupScheduled = false,
    this.pickupTokenNumber,
    this.pickupDate,
    this.expectedDeliveryDate,
    this.pickupSlot,
    this.shippingLabelUrl,
    this.shippingManifestUrl,
    this.deliveredAt,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    List<RequestModel>? requests,
    required this.type,
    required this.method,
    this.isAppOrder = false,
    this.abondonedOrder = true,
    required this.orderAmount,
    this.deliveryCharge = 0.0,
    this.discount = 0.0,
    this.gst,
    this.subtotal,
    this.name,
    this.email,
    this.phoneNo,
    this.address,
    this.addressId,
    this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.v,
  }) : requests = requests ?? [];

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] as String? ?? '', // Parsing MongoDB _id
      orderId: json['orderId'] as String? ?? '', // Parsing human-readable orderId
      status: json['status'] as String? ?? 'New',
      holdReason: json['holdReason'] as String?,
      shippingStatus: json['shippingStatus'] as String? ?? 'Pending',
      scans: (json['scans'] as List<dynamic>?)
          ?.map((e) => Scan.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',

      shipmentId: json['shipmentId'] as String?,
      shiprocketOrderId: json['shiprocketOrderId'] as String?,
      shiprocketChannelId: json['shiprocketChannelId'] as String?,
      awbCode: json['awbCode'] as String?,
      courierName: json['courierName'] as String?,
      courierAssignedAt: DateTime.tryParse(json['courierAssignedAt'] as String? ?? ''),
      pickupScheduled: json['pickupScheduled'] as bool? ?? false,
      pickupTokenNumber: json['pickupTokenNumber'] as String?,
      pickupDate: json['pickupDate'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      pickupSlot: json['pickupSlot'] as String?,
      shippingLabelUrl: json['shippingLabelUrl'] as String?,
      shippingManifestUrl: json['shippingManifestUrl'] as String?,
      deliveredAt: json['deliveredAt'] as String?,

      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,

      requests: (json['requests'] as List<dynamic>?)
          ?.map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],

      type: json['type'] as String? ?? 'Regular',
      method: json['method'] as String? ?? 'COD',
      isAppOrder: json['isAppOrder'] as bool? ?? false,
      abondonedOrder: json['abondonedOrder'] as bool? ?? true,

      orderAmount: (json['orderAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      gst: json['gst'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),

      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNo: json['phoneNo'] as String?,

      address: json['address'] as String?,
      addressId: json['addressId'] as String?,

      userId: json['userId'] != null && json['userId'] is Map
          ? OrderUserModel.fromJson(json['userId'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Include MongoDB _id when converting to JSON
      'orderId': orderId, // Include human-readable orderId when converting to JSON
      'status': status,
      'holdReason': holdReason,
      'shippingStatus': shippingStatus,
      'scans': scans?.map((e) => e.toJson()).toList(),
      'paymentStatus': paymentStatus,
      'shipmentId': shipmentId,
      'shiprocketOrderId': shiprocketOrderId,
      'shiprocketChannelId': shiprocketChannelId,
      'awbCode': awbCode,
      'courierName': courierName,
      'courierAssignedAt': courierAssignedAt?.toIso8601String(),
      'pickupScheduled': pickupScheduled,
      'pickupTokenNumber': pickupTokenNumber,
      'pickupDate': pickupDate,
      'expectedDeliveryDate': expectedDeliveryDate,
      'pickupSlot': pickupSlot,
      'shippingLabelUrl': shippingLabelUrl,
      'shippingManifestUrl': shippingManifestUrl,
      'deliveredAt': deliveredAt,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'requests': requests.map((e) => e.toJson()).toList(),
      'type': type,
      'method': method,
      'isAppOrder': isAppOrder,
      'abondonedOrder': abondonedOrder,
      'orderAmount': orderAmount,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'gst': gst,
      'subtotal': subtotal,
      'name': name,
      'email': email,
      'phoneNo': phoneNo,
      'address': address,
      'addressId': addressId,
      'userId': userId?.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}

class OrdersResponse {
  final int statusCode;
  final List<OrderModel> data;
  final String message;
  final bool success;

  OrdersResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
      'success': success,
    };
  }
}
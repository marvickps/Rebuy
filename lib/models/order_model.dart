import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,
}

enum ShippingMethod {
  courier,
  speedPost,
  pickup,
}

class OrderModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double productPrice;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final OrderStatus status;
  final ShippingMethod shippingMethod;
  final String? trackingNumber;
  final String? shippingCarrier;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final bool isPaid;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.status,
    required this.shippingMethod,
    this.trackingNumber,
    this.shippingCarrier,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
    this.notes,
    this.isPaid = false,
    this.paymentMethod = 'Cash on Delivery',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'productPrice': productPrice,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'status': status.name,
      'shippingMethod': shippingMethod.name,
      'trackingNumber': trackingNumber,
      'shippingCarrier': shippingCarrier,
      'deliveryAddress': deliveryAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'notes': notes,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productPrice: _parseDouble(map['productPrice']),
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      status: OrderStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      shippingMethod: ShippingMethod.values.firstWhere(
            (e) => e.name == map['shippingMethod'],
        orElse: () => ShippingMethod.courier,
      ),
      trackingNumber: map['trackingNumber'],
      shippingCarrier: map['shippingCarrier'],
      deliveryAddress: map['deliveryAddress'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      shippedAt: map['shippedAt'] != null ? _parseDateTime(map['shippedAt']) : null,
      deliveredAt: map['deliveredAt'] != null ? _parseDateTime(map['deliveredAt']) : null,
      notes: map['notes'],
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  OrderModel copyWith({
    OrderStatus? status,
    String? trackingNumber,
    String? shippingCarrier,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? notes,
    bool? isPaid,
  }) {
    return OrderModel(
      id: id,
      productId: productId,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      productPrice: productPrice,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      status: status ?? this.status,
      shippingMethod: shippingMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get shippingMethodDisplayName {
    switch (shippingMethod) {
      case ShippingMethod.courier:
        return 'Courier Service';
      case ShippingMethod.speedPost:
        return 'Speed Post';
      case ShippingMethod.pickup:
        return 'Self Pickup';
    }
  }
}
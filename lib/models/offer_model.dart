import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus {
  pending,
  accepted,
  rejected,
  countered,
  expired,
}

class OfferModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double originalPrice;
  final double offerAmount;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final OfferStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final String? counterOfferId; // For tracking counter offers
  final bool isCounterOffer;
  final String? originalOfferId; // Reference to original offer if this is a counter

  OfferModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.originalPrice,
    required this.offerAmount,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    this.status = OfferStatus.pending,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.counterOfferId,
    this.isCounterOffer = false,
    this.originalOfferId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'originalPrice': originalPrice,
      'offerAmount': offerAmount,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'status': status.name,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'counterOfferId': counterOfferId,
      'isCounterOffer': isCounterOffer,
      'originalOfferId': originalOfferId,
    };
  }

  factory OfferModel.fromMap(Map<String, dynamic> map) {
    return OfferModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      originalPrice: _parseDouble(map['originalPrice']),
      offerAmount: _parseDouble(map['offerAmount']),
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      status: OfferStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => OfferStatus.pending,
      ),
      message: map['message'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      expiresAt: _parseDateTime(map['expiresAt']),
      counterOfferId: map['counterOfferId'],
      isCounterOffer: map['isCounterOffer'] ?? false,
      originalOfferId: map['originalOfferId'],
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

  OfferModel copyWith({
    OfferStatus? status,
    String? message,
    String? counterOfferId,
  }) {
    return OfferModel(
      id: id,
      productId: productId,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      originalPrice: originalPrice,
      offerAmount: offerAmount,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiresAt: expiresAt,
      counterOfferId: counterOfferId ?? this.counterOfferId,
      isCounterOffer: isCounterOffer,
      originalOfferId: originalOfferId,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.countered:
        return 'Countered';
      case OfferStatus.expired:
        return 'Expired';
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get discountPercentage {
    if (originalPrice == 0) return 0;
    return ((originalPrice - offerAmount) / originalPrice) * 100;
  }
}
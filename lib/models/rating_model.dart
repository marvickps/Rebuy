import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String orderId;
  final String productId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int rating; // 1-5
  final String? review;
  final DateTime createdAt;
  final bool isSellerRating; // true if rating seller, false if rating buyer

  RatingModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.isSellerRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSellerRating': isSellerRating,
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      productId: map['productId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserId: map['toUserId'] ?? '',
      toUserName: map['toUserName'] ?? '',
      rating: map['rating'] ?? 0,
      review: map['review'],
      createdAt: _parseDateTime(map['createdAt']),
      isSellerRating: map['isSellerRating'] ?? true,
    );
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

  String get ratingText {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'No Rating';
    }
  }
}
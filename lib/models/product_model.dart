import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory {
  electronics,
  vehicles,
  properties,
  fashion,
  hobbies,
  furniture,
  books,
  sports,
  jobs,
  services,
  other,
}

enum ProductCondition { brandNew, likeNew, good, fair, poor }

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final ProductCategory category;
  final ProductCondition condition;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final int views;
  final List<String> tags;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.views = 0,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category.name,
      'condition': condition.name,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
      'views': views,
      'tags': tags,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: _parseDouble(map['price']),
      category: ProductCategory.values.firstWhere(
            (e) => e.name == map['category'],
        orElse: () => ProductCategory.other,
      ),
      condition: ProductCondition.values.firstWhere(
            (e) => e.name == map['condition'],
        orElse: () => ProductCondition.good,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      location: map['location'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      isAvailable: map['isAvailable'] ?? true,
      views: map['views'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Helper method to parse double values from various formats
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to parse DateTime from Firestore Timestamp or ISO String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // If it's a Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // If it's a String (ISO format)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string: $value, error: $e');
        return DateTime.now();
      }
    }

    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }

    // Fallback
    print('Unknown date format: $value (${value.runtimeType})');
    return DateTime.now();
  }

  ProductModel copyWith({
    String? title,
    String? description,
    double? price,
    ProductCategory? category,
    ProductCondition? condition,
    List<String>? imageUrls,
    String? location,
    bool? isAvailable,
    int? views,
    List<String>? tags,
  }) {
    return ProductModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isAvailable: isAvailable ?? this.isAvailable,
      views: views ?? this.views,
      tags: tags ?? this.tags,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case ProductCategory.electronics:
        return 'Electronics';
      case ProductCategory.vehicles:
        return 'Vehicles';
      case ProductCategory.properties:
        return 'Properties';
      case ProductCategory.fashion:
        return 'Fashion';
      case ProductCategory.hobbies:
        return 'Hobbies';
      case ProductCategory.furniture:
        return 'Furniture';
      case ProductCategory.books:
        return 'Books';
      case ProductCategory.sports:
        return 'Sports';
      case ProductCategory.jobs:
        return 'Jobs';
      case ProductCategory.services:
        return 'Services';
      case ProductCategory.other:
        return 'Other';
    }
  }

  String get conditionDisplayName {
    switch (condition) {
      case ProductCondition.brandNew:
        return 'Brand New';
      case ProductCondition.likeNew:
        return 'Like New';
      case ProductCondition.good:
        return 'Good';
      case ProductCondition.fair:
        return 'Fair';
      case ProductCondition.poor:
        return 'Poor';
    }
  }
}
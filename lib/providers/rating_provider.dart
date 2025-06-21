import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<RatingModel>> _userRatings = {};
  Map<String, List<RatingModel>> _productRatings = {};
  bool _isLoading = false;
  String _errorMessage = '';

  Map<String, List<RatingModel>> get userRatings => _userRatings;
  Map<String, List<RatingModel>> get productRatings => _productRatings;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Add a rating/review
  Future<bool> addRating({
    required String orderId,
    required String productId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required int rating,
    required bool isSellerRating,
    String? review,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if rating already exists for this order and user combination
      final existingRatingQuery = await _firestore
          .collection('ratings')
          .where('orderId', isEqualTo: orderId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('isSellerRating', isEqualTo: isSellerRating)
          .get();

      if (existingRatingQuery.docs.isNotEmpty) {
        _setError('You have already rated this ${isSellerRating ? 'buyer' : 'seller'}');
        _setLoading(false);
        return false;
      }

      final ratingId = _firestore.collection('ratings').doc().id;
      final ratingModel = RatingModel(
        id: ratingId,
        orderId: orderId,
        productId: productId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        rating: rating,
        review: review,
        createdAt: DateTime.now(),
        isSellerRating: isSellerRating,
      );

      await _firestore
          .collection('ratings')
          .doc(ratingId)
          .set(ratingModel.toMap());

      // Update local cache
      _addToCache(ratingModel);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add rating: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get ratings for a specific user (as seller or buyer)
  Future<List<RatingModel>> getUserRatings(String userId, {bool? isSellerRating}) async {
    try {
      Query query = _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (isSellerRating != null) {
        query = query.where('isSellerRating', isEqualTo: isSellerRating);
      }

      final querySnapshot = await query.get();
      final ratings = querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _userRatings[userId] = ratings;
      notifyListeners();
      return ratings;
    } catch (e) {
      _setError('Failed to get user ratings: ${e.toString()}');
      return [];
    }
  }

  // Get ratings for a specific product
  Future<List<RatingModel>> getProductRatings(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _productRatings[productId] = ratings;
      notifyListeners();
      return ratings;
    } catch (e) {
      _setError('Failed to get product ratings: ${e.toString()}');
      return [];
    }
  }

  // Check if user has already rated for a specific order
  Future<bool> hasUserRated(String orderId, String fromUserId, bool isSellerRating) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('orderId', isEqualTo: orderId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('isSellerRating', isEqualTo: isSellerRating)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get average rating for a user
  double getUserAverageRating(String userId, {bool? isSellerRating}) {
    final ratings = _userRatings[userId] ?? [];
    if (ratings.isEmpty) return 0.0;

    List<RatingModel> filteredRatings = ratings;
    if (isSellerRating != null) {
      filteredRatings = ratings.where((r) => r.isSellerRating == isSellerRating).toList();
    }

    if (filteredRatings.isEmpty) return 0.0;

    final sum = filteredRatings.fold<int>(0, (sum, rating) => sum + rating.rating);
    return sum / filteredRatings.length;
  }

  // Get rating count for a user
  int getUserRatingCount(String userId, {bool? isSellerRating}) {
    final ratings = _userRatings[userId] ?? [];
    if (isSellerRating == null) return ratings.length;

    return ratings.where((r) => r.isSellerRating == isSellerRating).length;
  }

  // Get average rating for a product
  double getProductAverageRating(String productId) {
    final ratings = _productRatings[productId] ?? [];
    if (ratings.isEmpty) return 0.0;

    final sum = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
    return sum / ratings.length;
  }

  // Get rating count for a product
  int getProductRatingCount(String productId) {
    return _productRatings[productId]?.length ?? 0;
  }

  // Get ratings given by a user
  Future<List<RatingModel>> getRatingsGivenByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _setError('Failed to get user given ratings: ${e.toString()}');
      return [];
    }
  }

  // Update a rating
  Future<bool> updateRating(String ratingId, {int? rating, String? review}) async {
    try {
      _setLoading(true);
      _clearError();

      Map<String, dynamic> updates = {};
      if (rating != null) updates['rating'] = rating;
      if (review != null) updates['review'] = review;

      await _firestore
          .collection('ratings')
          .doc(ratingId)
          .update(updates);

      // Update local cache
      _updateCacheRating(ratingId, updates);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update rating: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete a rating
  Future<bool> deleteRating(String ratingId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection('ratings')
          .doc(ratingId)
          .delete();

      // Remove from local cache
      _removeFromCache(ratingId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete rating: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _addToCache(RatingModel rating) {
    // Add to user ratings cache
    if (!_userRatings.containsKey(rating.toUserId)) {
      _userRatings[rating.toUserId] = [];
    }
    _userRatings[rating.toUserId]!.insert(0, rating);

    // Add to product ratings cache
    if (!_productRatings.containsKey(rating.productId)) {
      _productRatings[rating.productId] = [];
    }
    _productRatings[rating.productId]!.insert(0, rating);

    notifyListeners();
  }

  void _updateCacheRating(String ratingId, Map<String, dynamic> updates) {
    // Update in user ratings cache
    for (var userRatings in _userRatings.values) {
      final index = userRatings.indexWhere((r) => r.id == ratingId);
      if (index != -1) {
        final oldRating = userRatings[index];
        userRatings[index] = RatingModel(
          id: oldRating.id,
          orderId: oldRating.orderId,
          productId: oldRating.productId,
          fromUserId: oldRating.fromUserId,
          fromUserName: oldRating.fromUserName,
          toUserId: oldRating.toUserId,
          toUserName: oldRating.toUserName,
          rating: updates['rating'] ?? oldRating.rating,
          review: updates['review'] ?? oldRating.review,
          createdAt: oldRating.createdAt,
          isSellerRating: oldRating.isSellerRating,
        );
        break;
      }
    }

    // Update in product ratings cache
    for (var productRatings in _productRatings.values) {
      final index = productRatings.indexWhere((r) => r.id == ratingId);
      if (index != -1) {
        final oldRating = productRatings[index];
        productRatings[index] = RatingModel(
          id: oldRating.id,
          orderId: oldRating.orderId,
          productId: oldRating.productId,
          fromUserId: oldRating.fromUserId,
          fromUserName: oldRating.fromUserName,
          toUserId: oldRating.toUserId,
          toUserName: oldRating.toUserName,
          rating: updates['rating'] ?? oldRating.rating,
          review: updates['review'] ?? oldRating.review,
          createdAt: oldRating.createdAt,
          isSellerRating: oldRating.isSellerRating,
        );
        break;
      }
    }

    notifyListeners();
  }

  void _removeFromCache(String ratingId) {
    // Remove from user ratings cache
    for (var userRatings in _userRatings.values) {
      userRatings.removeWhere((r) => r.id == ratingId);
    }

    // Remove from product ratings cache
    for (var productRatings in _productRatings.values) {
      productRatings.removeWhere((r) => r.id == ratingId);
    }

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  void clearCache() {
    _userRatings.clear();
    _productRatings.clear();
    notifyListeners();
  }
}
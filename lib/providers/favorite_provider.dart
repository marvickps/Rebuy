import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _favoriteIds = [];
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialize favorites for a user
  Future<void> initializeFavorites(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _favoriteIds = List<String>.from(data['favorites'] ?? []);
        await _loadFavoriteProducts();
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load favorites: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load favorite products from IDs
  Future<void> _loadFavoriteProducts() async {
    if (_favoriteIds.isEmpty) {
      _favoriteProducts = [];
      notifyListeners();
      return;
    }

    try {
      // Firestore 'whereIn' has a limit of 10 items, so we need to batch
      final List<ProductModel> allProducts = [];

      for (int i = 0; i < _favoriteIds.length; i += 10) {
        final batch = _favoriteIds.skip(i).take(10).toList();

        final querySnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchProducts = querySnapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();

        allProducts.addAll(batchProducts);
      }

      _favoriteProducts = allProducts;
      notifyListeners();
    } catch (e) {
      print('Error loading favorite products: $e');
      _setError('Failed to load favorite products: ${e.toString()}');
    }
  }

  // Add product to favorites
  Future<bool> addToFavorites(String userId, String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        return true; // Already in favorites
      }

      // Update local state first for immediate UI feedback
      _favoriteIds.add(productId);
      notifyListeners();

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([productId]),
      });

      // Reload favorite products to include the new one
      await _loadFavoriteProducts();

      print('Product $productId added to favorites');
      return true;
    } catch (e) {
      // Revert local state if Firestore update failed
      _favoriteIds.remove(productId);
      notifyListeners();

      print('Error adding to favorites: $e');
      _setError('Failed to add to favorites: ${e.toString()}');
      return false;
    }
  }

  // Remove product from favorites
  Future<bool> removeFromFavorites(String userId, String productId) async {
    try {
      if (!_favoriteIds.contains(productId)) {
        return true; // Not in favorites
      }

      // Update local state first for immediate UI feedback
      _favoriteIds.remove(productId);
      _favoriteProducts.removeWhere((product) => product.id == productId);
      notifyListeners();

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([productId]),
      });

      print('Product $productId removed from favorites');
      return true;
    } catch (e) {
      // Revert local state if Firestore update failed
      _favoriteIds.add(productId);
      await _loadFavoriteProducts(); // Reload to restore the product

      print('Error removing from favorites: $e');
      _setError('Failed to remove from favorites: ${e.toString()}');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String userId, String productId) async {
    if (_favoriteIds.contains(productId)) {
      return await removeFromFavorites(userId, productId);
    } else {
      return await addToFavorites(userId, productId);
    }
  }

  // Check if product is in favorites
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  // Get favorite count
  int get favoriteCount => _favoriteIds.length;

  // Refresh favorites
  Future<void> refreshFavorites(String userId) async {
    await initializeFavorites(userId);
  }

  // Clear all favorites (for logout)
  void clearFavorites() {
    _favoriteIds = [];
    _favoriteProducts = [];
    _clearError();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    print('FavoritesProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
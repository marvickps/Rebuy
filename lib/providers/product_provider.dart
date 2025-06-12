import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  List<ProductModel> _products = [];
  List<ProductModel> _myProducts = [];
  List<ProductModel> _favoriteProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  ProductCategory? _selectedCategory;
  String _searchQuery = '';

  List<ProductModel> get products => _filteredProducts.isNotEmpty ? _filteredProducts : _products;
  List<ProductModel> get myProducts => _myProducts;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  ProductCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadProducts() async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _products = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> loadMyProducts(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _myProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load your products: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> loadFavoriteProducts(List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) {
      _favoriteProducts = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      _favoriteProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load favorite products: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required ProductCategory category,
    required ProductCondition condition,
    required List<File> images,
    required String sellerId,
    required String sellerName,
    required String sellerPhone,
    required String location,
    List<String> tags = const [],
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final productId = _uuid.v4();
      
      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('products/$productId/image_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final product = ProductModel(
        id: productId,
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        imageUrls: imageUrls,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhone: sellerPhone,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: tags,
      );

      await _firestore
          .collection('products')
          .doc(productId)
          .set(product.toMap());

      _products.insert(0, product);
      _myProducts.insert(0, product);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());

      // Update in local lists
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }

      final myIndex = _myProducts.indexWhere((p) => p.id == product.id);
      if (myIndex != -1) {
        _myProducts[myIndex] = product;
      }

      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('products').doc(productId).delete();

      // Delete images from storage
      try {
        final ref = _storage.ref().child('products/$productId');
        final listResult = await ref.listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        // Ignore storage deletion errors
      }

      _products.removeWhere((p) => p.id == productId);
      _myProducts.removeWhere((p) => p.id == productId);
      _favoriteProducts.removeWhere((p) => p.id == productId);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final product = ProductModel.fromMap(doc.data()!);
        // Increment view count
        await _firestore.collection('products').doc(productId).update({
          'views': FieldValue.increment(1),
        });
        return product.copyWith(views: product.views + 1);
      }
      return null;
    } catch (e) {
      _setError('Failed to get product: ${e.toString()}');
      return null;
    }
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void filterByCategory(ProductCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _applyFilters();
  }

  void _applyFilters() {
    List<ProductModel> filtered = List.from(_products);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(_searchQuery) ||
               p.description.toLowerCase().contains(_searchQuery) ||
               p.tags.any((tag) => tag.toLowerCase().contains(_searchQuery)) ||
               p.location.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredProducts = filtered;
    notifyListeners();
  }

  Future<List<ProductModel>> getProductsByCategory(ProductCategory category, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductModel>> getRelatedProducts(String productId, ProductCategory category, {int limit = 5}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1)
          .get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .where((p) => p.id != productId)
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      return [];
    }
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
}
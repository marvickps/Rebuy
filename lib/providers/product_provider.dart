import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

// Extension for ProductCategory display names
extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
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
}

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
  String? _selectedLocation;

  // Getters - FIXED: Always return filtered products when filters are active
  List<ProductModel> get products {
    if (hasActiveFilters) {
      return _filteredProducts;
    }
    return _products;
  }

  List<ProductModel> get myProducts => _myProducts;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  ProductCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get selectedLocation => _selectedLocation;

  // Check if any filters are active
  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        (_selectedLocation != null && _selectedLocation!.isNotEmpty);
  }

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

      print('Starting product addition...');
      print('Images count: ${images.length}');

      final productId = _uuid.v4();
      print('Generated product ID: $productId');

      // Upload images first
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        print('Uploading ${images.length} images...');
        for (int i = 0; i < images.length; i++) {
          try {
            print('Uploading image ${i + 1}/${images.length}...');
            final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final ref = _storage.ref().child('products/$productId/$fileName');

            // Upload with metadata
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
            );

            final uploadTask = ref.putFile(images[i], metadata);

            // Monitor upload progress
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              print('Upload ${i + 1} progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).round()}%');
            });

            await uploadTask;
            final url = await ref.getDownloadURL();
            imageUrls.add(url);
            print('Image ${i + 1} uploaded successfully: $url');
          } catch (e) {
            print('Error uploading image ${i + 1}: $e');
            throw Exception('Failed to upload image ${i + 1}: $e');
          }
        }
      }

      print('All images uploaded. URLs: $imageUrls');

      // Create product with proper data types
      final now = DateTime.now();
      final productData = {
        'id': productId,
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'category': category.name,
        'condition': condition.name,
        'imageUrls': imageUrls,
        'sellerId': sellerId,
        'sellerName': sellerName.trim(),
        'sellerPhone': sellerPhone.trim(),
        'location': location.trim(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isAvailable': true,
        'views': 0,
        'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
      };

      print('Saving product to Firestore...');
      print('Product data: $productData');

      // Save to Firestore with proper error handling
      await _firestore
          .collection('products')
          .doc(productId)
          .set(productData);

      print('Product saved to Firestore successfully!');

      // Create ProductModel for local state
      final product = ProductModel(
        id: productId,
        title: title.trim(),
        description: description.trim(),
        price: price,
        category: category,
        condition: condition,
        imageUrls: imageUrls,
        sellerId: sellerId,
        sellerName: sellerName.trim(),
        sellerPhone: sellerPhone.trim(),
        location: location.trim(),
        createdAt: now,
        updatedAt: now,
        tags: tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
      );

      // Update local state
      _products.insert(0, product);
      _myProducts.insert(0, product);
      _applyFilters();
      _setLoading(false);

      print('Product added successfully to local state');
      return true;
    } catch (e) {
      print('Error adding product: $e');
      _setError('Failed to add product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _clearError();

      print('Updating product: ${product.id}');

      // Prepare update data
      final updateData = {
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'category': product.category.name,
        'condition': product.condition.name,
        'location': product.location,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isAvailable': product.isAvailable,
        'tags': product.tags,
      };

      // Only update imageUrls if they exist (in case of image updates)
      if (product.imageUrls.isNotEmpty) {
        updateData['imageUrls'] = product.imageUrls;
      }

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updateData);

      print('Product updated in Firestore successfully');

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
      print('Error updating product: $e');
      _setError('Failed to update product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      print('Deleting product: $productId');

      await _firestore.collection('products').doc(productId).delete();

      // Delete images from storage
      try {
        final ref = _storage.ref().child('products/$productId');
        final listResult = await ref.listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
        print('Product images deleted from storage');
      } catch (e) {
        print('Error deleting storage files (non-critical): $e');
        // Don't fail the entire operation if storage cleanup fails
      }

      _products.removeWhere((p) => p.id == productId);
      _myProducts.removeWhere((p) => p.id == productId);
      _favoriteProducts.removeWhere((p) => p.id == productId);
      _applyFilters();
      _setLoading(false);

      print('Product deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      _setError('Failed to delete product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      print('Fetching product: $productId');

      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        final product = ProductModel.fromMap(doc.data()!);

        // Increment view count
        await _firestore.collection('products').doc(productId).update({
          'views': FieldValue.increment(1),
        });

        return product.copyWith(views: product.views + 1);
      }
      print('Product not found: $productId');
      return null;
    } catch (e) {
      print('Error getting product: $e');
      _setError('Failed to get product: ${e.toString()}');
      return null;
    }
  }

  // Filter methods
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
  }

  void filterByCategory(ProductCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void filterByLocation(String location) {
    _selectedLocation = location.trim().isEmpty ? null : location.trim().toLowerCase();
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _selectedLocation = null;
    _filteredProducts = [];
    notifyListeners();
  }

  // FIXED: Apply filters method - properly handle empty results
  void _applyFilters() {
    print('Applying filters...');
    print('Selected category: $_selectedCategory');
    print('Search query: "$_searchQuery"');
    print('Selected location: "$_selectedLocation"');
    print('Total products: ${_products.length}');

    // Start with all products
    List<ProductModel> filtered = List.from(_products);

    // Apply category filter first
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
      print('After category filter: ${filtered.length} products');
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final titleMatch = p.title.toLowerCase().contains(_searchQuery);
        final descriptionMatch = p.description.toLowerCase().contains(_searchQuery);
        final tagsMatch = p.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        final locationMatch = p.location.toLowerCase().contains(_searchQuery);

        return titleMatch || descriptionMatch || tagsMatch || locationMatch;
      }).toList();
      print('After search filter: ${filtered.length} products');
    }

    // Apply location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.location.toLowerCase().contains(_selectedLocation!);
      }).toList();
      print('After location filter: ${filtered.length} products');
    }

    // IMPORTANT: Always set filtered products, even if empty
    _filteredProducts = filtered;
    print('Final filtered products: ${_filteredProducts.length}');

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
      print('Error getting products by category: $e');
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
      print('Error getting related products: $e');
      return [];
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    print('ProductProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
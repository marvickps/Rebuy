import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class OfferProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OfferModel> _sentOffers = [];
  List<OfferModel> _receivedOffers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OfferModel> get sentOffers => _sentOffers;
  List<OfferModel> get receivedOffers => _receivedOffers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create a new offer
  Future<String?> createOffer({
    required ProductModel product,
    required UserModel buyer,
    required double offerAmount,
    String? message,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if buyer has any pending offers for this product
      final existingOffers = await _firestore
          .collection('offers')
          .where('productId', isEqualTo: product.id)
          .where('buyerId', isEqualTo: buyer.uid)
          .where('status', isEqualTo: OfferStatus.pending.name)
          .get();

      if (existingOffers.docs.isNotEmpty) {
        _setError('You already have a pending offer for this product');
        return null;
      }

      final String offerId = _firestore.collection('offers').doc().id;
      final DateTime now = DateTime.now();
      final DateTime expiresAt = now.add(const Duration(days: 7)); // Offers expire in 7 days

      final offer = OfferModel(
        id: offerId,
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        originalPrice: product.price,
        offerAmount: offerAmount,
        buyerId: buyer.uid,
        buyerName: buyer.name,
        buyerPhone: buyer.phone,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        sellerPhone: product.sellerPhone,
        status: OfferStatus.pending,
        message: message,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
      );

      await _firestore.collection('offers').doc(offerId).set(offer.toMap());

      // Add to local list
      _sentOffers.add(offer);
      notifyListeners();

      return offerId;
    } catch (e) {
      _setError('Failed to create offer: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Accept an offer
  Future<bool> acceptOffer(String offerId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('offers').doc(offerId).update({
        'status': OfferStatus.accepted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local data
      _updateLocalOfferStatus(offerId, OfferStatus.accepted);
      return true;
    } catch (e) {
      _setError('Failed to accept offer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject an offer
  Future<bool> rejectOffer(String offerId, {String? reason}) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('offers').doc(offerId).update({
        'status': OfferStatus.rejected.name,
        'message': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local data
      _updateLocalOfferStatus(offerId, OfferStatus.rejected, message: reason);
      return true;
    } catch (e) {
      _setError('Failed to reject offer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create counter offer
  Future<String?> createCounterOffer({
    required String originalOfferId,
    required double counterAmount,
    String? message,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // First, get the original offer
      final originalOfferDoc = await _firestore
          .collection('offers')
          .doc(originalOfferId)
          .get();

      if (!originalOfferDoc.exists) {
        _setError('Original offer not found');
        return null;
      }

      final originalOffer = OfferModel.fromMap(originalOfferDoc.data()!);

      // Update original offer status to countered
      await _firestore.collection('offers').doc(originalOfferId).update({
        'status': OfferStatus.countered.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create counter offer
      final String counterOfferId = _firestore.collection('offers').doc().id;
      final DateTime now = DateTime.now();
      final DateTime expiresAt = now.add(const Duration(days: 7));

      final counterOffer = OfferModel(
        id: counterOfferId,
        productId: originalOffer.productId,
        productTitle: originalOffer.productTitle,
        productImageUrl: originalOffer.productImageUrl,
        originalPrice: originalOffer.originalPrice,
        offerAmount: counterAmount,
        buyerId: originalOffer.buyerId,
        buyerName: originalOffer.buyerName,
        buyerPhone: originalOffer.buyerPhone,
        sellerId: originalOffer.sellerId,
        sellerName: originalOffer.sellerName,
        sellerPhone: originalOffer.sellerPhone,
        status: OfferStatus.pending,
        message: message,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
        isCounterOffer: true,
        originalOfferId: originalOfferId,
      );

      await _firestore.collection('offers').doc(counterOfferId).set(counterOffer.toMap());

      // Update original offer with counter offer reference
      await _firestore.collection('offers').doc(originalOfferId).update({
        'counterOfferId': counterOfferId,
      });

      // Update local data
      _updateLocalOfferStatus(originalOfferId, OfferStatus.countered);
      _sentOffers.add(counterOffer);
      notifyListeners();

      return counterOfferId;
    } catch (e) {
      _setError('Failed to create counter offer: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update offer order status - NEW METHOD
  Future<bool> updateOfferOrderStatus(String offerId, bool hasOrder) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('offers').doc(offerId).update({
        'orderCreated': hasOrder,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local data if the offer exists
      final sentIndex = _sentOffers.indexWhere((offer) => offer.id == offerId);
      if (sentIndex != -1) {
        // Note: You might want to add orderCreated field to OfferModel
        // For now, we'll just update the updatedAt timestamp
        _sentOffers[sentIndex] = _sentOffers[sentIndex].copyWith();
      }

      final receivedIndex = _receivedOffers.indexWhere((offer) => offer.id == offerId);
      if (receivedIndex != -1) {
        _receivedOffers[receivedIndex] = _receivedOffers[receivedIndex].copyWith();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update offer order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete offer - NEW METHOD
  Future<bool> deleteOffer(String offerId) async {
    try {
      _setLoading(true);
      _clearError();

      // Delete from Firestore
      await _firestore.collection('offers').doc(offerId).delete();

      // Remove from local lists
      _sentOffers.removeWhere((offer) => offer.id == offerId);
      _receivedOffers.removeWhere((offer) => offer.id == offerId);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete offer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load offers for current user
  Future<void> loadUserOffers(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      print('Loading offers for user: $userId'); // Debug log

      // Load sent offers (where user is buyer)
      final sentQuery = await _firestore
          .collection('offers')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${sentQuery.docs.length} sent offers'); // Debug log

      _sentOffers = sentQuery.docs
          .map((doc) {
        try {
          return OfferModel.fromMap(doc.data());
        } catch (e) {
          print('Error parsing sent offer: $e');
          return null;
        }
      })
          .where((offer) => offer != null)
          .cast<OfferModel>()
          .toList();

      // Load received offers (where user is seller)
      final receivedQuery = await _firestore
          .collection('offers')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${receivedQuery.docs.length} received offers'); // Debug log

      _receivedOffers = receivedQuery.docs
          .map((doc) {
        try {
          return OfferModel.fromMap(doc.data());
        } catch (e) {
          print('Error parsing received offer: $e');
          return null;
        }
      })
          .where((offer) => offer != null)
          .cast<OfferModel>()
          .toList();

      print('Loaded ${_sentOffers.length} sent offers and ${_receivedOffers.length} received offers'); // Debug log
      notifyListeners();
    } catch (e) {
      print('Error loading offers: $e');
      _setError('Failed to load offers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get offers for a specific product
  Future<List<OfferModel>> getProductOffers(String productId) async {
    try {
      final query = await _firestore
          .collection('offers')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => OfferModel.fromMap(doc.data()))
          .where((offer) => !offer.isExpired)
          .toList();
    } catch (e) {
      print('Error getting product offers: $e');
      return [];
    }
  }

  // Get a specific offer
  Future<OfferModel?> getOffer(String offerId) async {
    try {
      final doc = await _firestore.collection('offers').doc(offerId).get();
      if (doc.exists) {
        return OfferModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting offer: $e');
      return null;
    }
  }

  // Listen to offer updates in real-time
  Stream<OfferModel?> listenToOffer(String offerId) {
    return _firestore
        .collection('offers')
        .doc(offerId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return OfferModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Listen to user offers in real-time
  Stream<List<OfferModel>> listenToUserOffers(String userId, {bool isSeller = false}) {
    final field = isSeller ? 'sellerId' : 'buyerId';

    return _firestore
        .collection('offers')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OfferModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Check if user has pending offer for product
  Future<bool> hasPendingOffer(String productId, String buyerId) async {
    try {
      final query = await _firestore
          .collection('offers')
          .where('productId', isEqualTo: productId)
          .where('buyerId', isEqualTo: buyerId)
          .where('status', isEqualTo: OfferStatus.pending.name)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending offer: $e');
      return false;
    }
  }

  // Get latest offer for a product from a buyer
  Future<OfferModel?> getLatestOfferForProduct(String productId, String buyerId) async {
    try {
      final query = await _firestore
          .collection('offers')
          .where('productId', isEqualTo: productId)
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return OfferModel.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting latest offer: $e');
      return null;
    }
  }

  // Private helper methods
  void _updateLocalOfferStatus(String offerId, OfferStatus status, {String? message}) {
    // Update in sent offers
    final sentIndex = _sentOffers.indexWhere((offer) => offer.id == offerId);
    if (sentIndex != -1) {
      _sentOffers[sentIndex] = _sentOffers[sentIndex].copyWith(
        status: status,
        message: message,
      );
    }

    // Update in received offers
    final receivedIndex = _receivedOffers.indexWhere((offer) => offer.id == offerId);
    if (receivedIndex != -1) {
      _receivedOffers[receivedIndex] = _receivedOffers[receivedIndex].copyWith(
        status: status,
        message: message,
      );
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
    _errorMessage = null;
  }

  // Clear all data
  void clear() {
    _sentOffers.clear();
    _receivedOffers.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
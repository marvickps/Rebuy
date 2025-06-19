// lib/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  List<OrderModel> _buyerOrders = [];
  List<OrderModel> _sellerOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<OrderModel> get orders => _orders;
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<OrderModel> get sellerOrders => _sellerOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create a new order
  Future<bool> createOrder(OrderModel order) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Generate a new document reference to get the ID
      final docRef = _firestore.collection('orders').doc();

      // Create order with the generated ID
      final newOrder = OrderModel(
        id: docRef.id,
        productId: order.productId,
        productTitle: order.productTitle,
        productImageUrl: order.productImageUrl,
        productPrice: order.productPrice,
        buyerId: order.buyerId,
        buyerName: order.buyerName,
        buyerPhone: order.buyerPhone,
        sellerId: order.sellerId,
        sellerName: order.sellerName,
        sellerPhone: order.sellerPhone,
        status: order.status,
        shippingMethod: order.shippingMethod,
        deliveryAddress: order.deliveryAddress,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        paymentMethod: order.paymentMethod,
        isPaid: order.isPaid,
      );

      await docRef.set(newOrder.toMap());

      // Add to local lists
      _orders.add(newOrder);

      if (newOrder.buyerId == order.buyerId) {
        _buyerOrders.add(newOrder);
      }
      if (newOrder.sellerId == order.sellerId) {
        _sellerOrders.add(newOrder);
      }

      print('Order created successfully: ${newOrder.id}');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create order: $e';
      print('Error creating order: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load orders for a specific user
  Future<void> loadUserOrders(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load orders where user is buyer
      final buyerQuery = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Load orders where user is seller
      final sellerQuery = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _buyerOrders = buyerQuery.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();

      _sellerOrders = sellerQuery.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();

      // Combine all orders for general access
      _orders = [..._buyerOrders, ..._sellerOrders];

      // Remove duplicates if user is both buyer and seller for same order
      final Map<String, OrderModel> uniqueOrders = {};
      for (final order in _orders) {
        uniqueOrders[order.id] = order;
      }
      _orders = uniqueOrders.values.toList();

      // Sort by creation date
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Loaded ${_orders.length} orders for user: $userId');
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
      print('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Add timestamp for specific status changes
      switch (status) {
        case OrderStatus.shipped:
          updateData['shippedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case OrderStatus.delivered:
          updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Update local data
      _updateLocalOrder(orderId, (order) => order.copyWith(
        status: status,
        shippedAt: status == OrderStatus.shipped ? DateTime.now() : order.shippedAt,
        deliveredAt: status == OrderStatus.delivered ? DateTime.now() : order.deliveredAt,
      ));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update order status: $e';
      print('Error updating order status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, bool isPaid, {String? paymentMethod}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updateData = <String, dynamic>{
        'isPaid': isPaid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }

      // If payment is successful, also update status to confirmed
      if (isPaid) {
        updateData['status'] = OrderStatus.confirmed.name;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Update local data
      _updateLocalOrder(orderId, (order) => order.copyWith(
        isPaid: isPaid,
        status: isPaid ? OrderStatus.confirmed : order.status,
      ));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update payment status: $e';
      print('Error updating payment status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add tracking information
  Future<bool> addTrackingInfo(String orderId, String trackingNumber, String carrier) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'trackingNumber': trackingNumber,
        'shippingCarrier': carrier,
        'status': OrderStatus.shipped.name,
        'shippedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local data
      _updateLocalOrder(orderId, (order) => order.copyWith(
        trackingNumber: trackingNumber,
        shippingCarrier: carrier,
        status: OrderStatus.shipped,
        shippedAt: DateTime.now(),
      ));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add tracking info: $e';
      print('Error adding tracking info: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'notes': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local data
      _updateLocalOrder(orderId, (order) => order.copyWith(
        status: OrderStatus.cancelled,
        notes: reason,
      ));

      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel order: $e';
      print('Error cancelling order: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order by ID
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Get orders by product ID
  List<OrderModel> getOrdersByProductId(String productId) {
    return _orders.where((order) => order.productId == productId).toList();
  }

  // Helper method to update local order data
  void _updateLocalOrder(String orderId, OrderModel Function(OrderModel) updateFunction) {
    // Update in main orders list
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex] = updateFunction(_orders[orderIndex]);
    }

    // Update in buyer orders list
    final buyerIndex = _buyerOrders.indexWhere((order) => order.id == orderId);
    if (buyerIndex != -1) {
      _buyerOrders[buyerIndex] = updateFunction(_buyerOrders[buyerIndex]);
    }

    // Update in seller orders list
    final sellerIndex = _sellerOrders.indexWhere((order) => order.id == orderId);
    if (sellerIndex != -1) {
      _sellerOrders[sellerIndex] = updateFunction(_sellerOrders[sellerIndex]);
    }
  }

  // Real-time listener for orders (optional)
  void startOrderListener(String userId) {
    // Listen to buyer orders
    _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _buyerOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
      _updateCombinedOrders();
    });

    // Listen to seller orders
    _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _sellerOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
      _updateCombinedOrders();
    });
  }

  void _updateCombinedOrders() {
    final Map<String, OrderModel> uniqueOrders = {};

    for (final order in [..._buyerOrders, ..._sellerOrders]) {
      uniqueOrders[order.id] = order;
    }

    _orders = uniqueOrders.values.toList();
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _orders.clear();
    _buyerOrders.clear();
    _sellerOrders.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/order_header_widget.dart';
import 'widgets/order_timeline_widget.dart';
import 'widgets/product_details_widget.dart';
import 'widgets/shipping_info_widget.dart';
import 'widgets/delivery_address_widget.dart';
import 'widgets/order_details_widget.dart';
import 'widgets/order_actions_widget.dart';
import 'widgets/order_notes_widget.dart';


class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user?.uid != null) {
      await orderProvider.loadUserOrders(authProvider.user!.uid);
      final updatedOrder = orderProvider.getOrderById(_currentOrder.id);
      if (updatedOrder != null) {
        setState(() {
          _currentOrder = updatedOrder;
        });
      }
    }
  }

  bool _isUserSeller() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.uid == _currentOrder.sellerId;
  }

  bool _isUserBuyer() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.uid == _currentOrder.buyerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: const Color(0xFF078893),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _refreshOrder,
            tooltip: 'Refresh Order',
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return RefreshIndicator(
            onRefresh: _refreshOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header
                  OrderHeaderWidget(order: _currentOrder),
                  const SizedBox(height: 24),

                  // Order Status Timeline
                  OrderTimelineWidget(order: _currentOrder),
                  const SizedBox(height: 24),

                  // Product Details
                  ProductDetailsWidget(order: _currentOrder),
                  const SizedBox(height: 24),

                  // Shipping Information
                  if (_currentOrder.status == OrderStatus.shipped ||
                      _currentOrder.status == OrderStatus.delivered)
                    ShippingInfoWidget(order: _currentOrder),

                  // Delivery Address
                  DeliveryAddressWidget(order: _currentOrder),
                  const SizedBox(height: 24),

                  // Order Details
                  OrderDetailsWidget(order: _currentOrder),
                  const SizedBox(height: 24),

                  // Action Buttons
                  OrderActionsWidget(
                    order: _currentOrder,
                    isUserSeller: _isUserSeller(),
                    isUserBuyer: _isUserBuyer(),
                    onRefresh: _refreshOrder,
                  ),

                  // Notes section
                  if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty)
                    OrderNotesWidget(order: _currentOrder),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

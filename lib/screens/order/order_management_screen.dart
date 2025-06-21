// lib/screens/order/order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../product/order_tracking_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.user?.uid != null) {
      setState(() => _isLoading = true);
      await orderProvider.loadUserOrders(authProvider.user!.uid);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF078893),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_bag_outlined),
              text: 'Buying',
            ),
            Tab(
              icon: Icon(Icons.sell_outlined),
              text: 'Selling',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBuyingOrdersTab(),
          _buildSellingOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildBuyingOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final buyingOrders = orderProvider.buyerOrders;

        if (buyingOrders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Buying Orders',
            message: 'You haven\'t placed any orders yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buyingOrders.length,
            itemBuilder: (context, index) {
              final order = buyingOrders[index];
              return _buildOrderCard(order, isBuying: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildSellingOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final sellingOrders = orderProvider.sellerOrders;

        if (sellingOrders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sell_outlined,
            title: 'No Selling Orders',
            message: 'You haven\'t received any orders yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellingOrders.length,
            itemBuilder: (context, index) {
              final order = sellingOrders[index];
              return _buildOrderCard(order, isBuying: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isBuying}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF078893),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 16),

              // Product Info
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: order.productImageUrl.isNotEmpty
                          ? Image.network(
                        order.productImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                      )
                          : const Icon(Icons.image_not_supported),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${order.productPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF078893),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBuying
                              ? 'Seller: ${order.sellerName}'
                              : 'Buyer: ${order.buyerName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Order Details
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.payment,
                    label: order.isPaid ? 'Paid' : 'Unpaid',
                    color: order.isPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.local_shipping,
                    label: order.shippingMethodDisplayName,
                    color: Colors.blue,
                  ),
                ],
              ),

              // Tracking Info (if available)
              if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracking Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              order.trackingNumber!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (order.shippingCarrier != null)
                              Text(
                                'via ${order.shippingCarrier}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              if (_shouldShowActions(order, isBuying)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (order.status == OrderStatus.pending && !isBuying)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddTrackingDialog(order),
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Add Tracking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF078893),
                            side: const BorderSide(color: Color(0xFF078893)),
                          ),
                        ),
                      ),
                    if (order.status == OrderStatus.shipped && isBuying) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsDelivered(order),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Delivered'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  bool _shouldShowActions(OrderModel order, bool isBuying) {
    if (order.status == OrderStatus.pending && !isBuying) return true;
    if (order.status == OrderStatus.shipped && isBuying) return true;
    return false;
  }

  Future<void> _showAddTrackingDialog(OrderModel order) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tracking Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(
                labelText: 'Shipping Carrier',
                hintText: 'e.g., Blue Dart, DTDC, India Post',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (trackingController.text.trim().isNotEmpty &&
                  carrierController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add Tracking'),
          ),
        ],
      ),
    );

    if (result == true) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.addTrackingInfo(
        order.id,
        trackingController.text.trim(),
        carrierController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tracking information added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    }
  }

  Future<void> _markAsDelivered(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Have you received the product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Mark as Delivered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.updateOrderStatus(
        order.id,
        OrderStatus.delivered,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    }
  }
}
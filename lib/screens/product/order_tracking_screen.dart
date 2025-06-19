// lib/screens/product/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

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
  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _carrierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _refreshOrder();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _carrierController.dispose();
    _notesController.dispose();
    super.dispose();
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
                  _buildOrderHeader(),
                  const SizedBox(height: 24),

                  // Order Status Timeline
                  _buildStatusTimeline(),
                  const SizedBox(height: 24),

                  // Product Details
                  _buildProductDetails(),
                  const SizedBox(height: 24),

                  // Shipping Information
                  if (_currentOrder.status == OrderStatus.shipped ||
                      _currentOrder.status == OrderStatus.delivered)
                    _buildShippingInfo(),

                  // Delivery Address
                  _buildDeliveryAddress(),
                  const SizedBox(height: 24),

                  // Order Details
                  _buildOrderDetails(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(orderProvider),

                  // Notes section
                  if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty)
                    _buildNotesSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentOrder.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(_currentOrder.status),
                    color: _getStatusColor(_currentOrder.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${_currentOrder.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentOrder.statusDisplayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: _getStatusColor(_currentOrder.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentOrder.isPaid ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentOrder.isPaid ? 'Paid' : 'Payment Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _currentOrder.isPaid ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Ordered ${DateFormat('MMM dd, yyyy').format(_currentOrder.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTimelineStep(
              OrderStatus.pending,
              'Order Placed',
              'Your order has been placed successfully',
              _currentOrder.createdAt,
              true,
            ),
            _buildTimelineStep(
              OrderStatus.confirmed,
              'Order Confirmed',
              'Payment confirmed and order is being processed',
              _currentOrder.updatedAt,
              _currentOrder.status.index >= OrderStatus.confirmed.index,
            ),
            _buildTimelineStep(
              OrderStatus.shipped,
              'Order Shipped',
              'Your order is on the way',
              _currentOrder.shippedAt,
              _currentOrder.status.index >= OrderStatus.shipped.index,
            ),
            _buildTimelineStep(
              OrderStatus.delivered,
              'Order Delivered',
              'Your order has been delivered successfully',
              _currentOrder.deliveredAt,
              _currentOrder.status.index >= OrderStatus.delivered.index,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
      OrderStatus status,
      String title,
      String subtitle,
      DateTime? timestamp,
      bool isCompleted, {
        bool isLast = false,
      }) {
    final bool isCurrent = _currentOrder.status == status;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? _getStatusColor(status)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? LucideIcons.check : _getStatusIcon(status),
                size: 12,
                color: isCompleted ? Colors.white : Colors.grey[600],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? _getStatusColor(status) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (timestamp != null && isCompleted)
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _currentOrder.productImageUrl.isNotEmpty
                      ? Image.network(
                    _currentOrder.productImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.image, color: Colors.grey),
                      );
                    },
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(LucideIcons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: ₹${_currentOrder.productPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF078893),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${_currentOrder.paymentMethod}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.truck, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Shipping Method: ${_currentOrder.shippingMethodDisplayName}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (_currentOrder.trackingNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.package, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking Number: ${_currentOrder.trackingNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (_currentOrder.shippingCarrier != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.building, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Carrier: ${_currentOrder.shippingCarrier}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            if (_currentOrder.shippedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.calendar, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Shipped: ${DateFormat('MMM dd, yyyy • hh:mm a').format(_currentOrder.shippedAt!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.mapPin, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentOrder.deliveryAddress.isNotEmpty
                  ? _currentOrder.deliveryAddress
                  : 'Address not provided',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Order ID', '#${_currentOrder.id.substring(0, 8).toUpperCase()}'),
            _buildDetailRow('Buyer', _currentOrder.buyerName),
            _buildDetailRow('Seller', _currentOrder.sellerName),
            _buildDetailRow('Order Date', DateFormat('MMM dd, yyyy • hh:mm a').format(_currentOrder.createdAt)),
            _buildDetailRow('Payment Status', _currentOrder.isPaid ? 'Paid' : 'Pending'),
            _buildDetailRow('Payment Method', _currentOrder.paymentMethod),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderProvider orderProvider) {
    List<Widget> buttons = [];

    // Seller actions
    if (_isUserSeller()) {
      if (_currentOrder.status == OrderStatus.confirmed) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _showAddTrackingDialog(orderProvider),
            icon: const Icon(LucideIcons.truck),
            label: const Text('Add Tracking Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078893),
              foregroundColor: Colors.white,
            ),
          ),
        );
      }

      if (_currentOrder.status == OrderStatus.shipped) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _markAsDelivered(orderProvider),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Mark as Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    // Buyer actions
    if (_isUserBuyer()) {
      if (_currentOrder.status == OrderStatus.shipped) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _confirmDelivery(orderProvider),
            icon: const Icon(LucideIcons.checkCircle),
            label: const Text('Confirm Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    // Common actions
    if (_currentOrder.status != OrderStatus.cancelled &&
        _currentOrder.status != OrderStatus.delivered) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showCancelDialog(orderProvider),
          icon: const Icon(LucideIcons.x),
          label: const Text('Cancel Order'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: buttons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.fileText, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'Order Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _currentOrder.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTrackingDialog(OrderProvider orderProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tracking Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _carrierController,
              decoration: const InputDecoration(
                labelText: 'Shipping Carrier',
                border: OutlineInputBorder(),
                hintText: 'e.g., Blue Dart, DTDC, India Post',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_trackingController.text.trim().isNotEmpty &&
                  _carrierController.text.trim().isNotEmpty) {
                final success = await orderProvider.addTrackingInfo(
                  _currentOrder.id,
                  _trackingController.text.trim(),
                  _carrierController.text.trim(),
                );

                Navigator.pop(context);

                if (success) {
                  await _refreshOrder();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking information added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(orderProvider.errorMessage ?? 'Failed to add tracking info'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Tracking'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsDelivered(OrderProvider orderProvider) async {
    final success = await orderProvider.updateOrderStatus(
      _currentOrder.id,
      OrderStatus.delivered,
    );

    if (success) {
      await _refreshOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to update order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelivery(OrderProvider orderProvider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Have you received your order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await orderProvider.updateOrderStatus(
        _currentOrder.id,
        OrderStatus.delivered,
      );

      if (success) {
        await _refreshOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for confirming delivery!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to confirm delivery'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCancelDialog(OrderProvider orderProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await orderProvider.cancelOrder(
                _currentOrder.id,
                _notesController.text.trim().isEmpty
                    ? 'Order cancelled by user'
                    : _notesController.text.trim(),
              );

              Navigator.pop(context);

              if (success) {
                await _refreshOrder();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(orderProvider.errorMessage ?? 'Failed to cancel order'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
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
        return LucideIcons.clock;
      case OrderStatus.confirmed:
        return LucideIcons.checkCircle;
      case OrderStatus.shipped:
        return LucideIcons.truck;
      case OrderStatus.delivered:
        return LucideIcons.package;
      case OrderStatus.cancelled:
        return LucideIcons.x;
    }
  }
}
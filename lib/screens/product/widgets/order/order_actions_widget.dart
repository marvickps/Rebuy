// widgets/order_actions_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/order_model.dart';
import '../../../../providers/order_provider.dart';
import 'order_dialogs.dart';

class OrderActionsWidget extends StatelessWidget {
  final OrderModel order;
  final bool isUserSeller;
  final bool isUserBuyer;
  final VoidCallback onRefresh;

  const OrderActionsWidget({
    super.key,
    required this.order,
    required this.isUserSeller,
    required this.isUserBuyer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    List<Widget> buttons = [];

    // Seller actions
    if (isUserSeller) {
      if (order.status == OrderStatus.confirmed) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _showAddTrackingDialog(context, orderProvider),
            icon: const Icon(LucideIcons.truck),
            label: const Text('Add Tracking Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078893),
              foregroundColor: Colors.white,
            ),
          ),
        );
      }

      if (order.status == OrderStatus.shipped) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _markAsDelivered(context, orderProvider),
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
    if (isUserBuyer) {
      if (order.status == OrderStatus.shipped) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _confirmDelivery(context, orderProvider),
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
    if (order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showCancelDialog(context, orderProvider),
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

  Future<void> _showAddTrackingDialog(BuildContext context, OrderProvider orderProvider) async {
    final result = await OrderDialogs.showAddTrackingDialog(context);

    if (result != null) {
      final success = await orderProvider.addTrackingInfo(
        order.id,
        result['trackingNumber']!,
        result['carrier']!,
      );

      if (context.mounted) {
        if (success) {
          onRefresh();
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
    }
  }

  Future<void> _markAsDelivered(BuildContext context, OrderProvider orderProvider) async {
    final success = await orderProvider.updateOrderStatus(
      order.id,
      OrderStatus.delivered,
    );

    if (context.mounted) {
      if (success) {
        onRefresh();
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
  }

  Future<void> _confirmDelivery(BuildContext context, OrderProvider orderProvider) async {
    final confirmed = await OrderDialogs.showConfirmDeliveryDialog(context);

    if (confirmed == true) {
      final success = await orderProvider.updateOrderStatus(
        order.id,
        OrderStatus.delivered,
      );

      if (context.mounted) {
        if (success) {
          onRefresh();
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
  }

  Future<void> _showCancelDialog(BuildContext context, OrderProvider orderProvider) async {
    final reason = await OrderDialogs.showCancelOrderDialog(context);

    if (reason != null) {
      final success = await orderProvider.cancelOrder(
        order.id,
        reason.isEmpty ? 'Order cancelled by user' : reason,
      );

      if (context.mounted) {
        if (success) {
          onRefresh();
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
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:rebuy/screens/product/widgets/timeline_step_widget.dart';
import '../../../../models/order_model.dart';


class OrderTimelineWidget extends StatelessWidget {
  final OrderModel order;

  const OrderTimelineWidget({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
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
            TimelineStepWidget(
              status: OrderStatus.pending,
              title: 'Order Placed',
              subtitle: 'Your order has been placed successfully',
              timestamp: order.createdAt,
              isCompleted: true,
              currentOrderStatus: order.status,
            ),
            TimelineStepWidget(
              status: OrderStatus.confirmed,
              title: 'Order Confirmed',
              subtitle: 'Payment confirmed and order is being processed',
              timestamp: order.updatedAt,
              isCompleted: order.status.index >= OrderStatus.confirmed.index,
              currentOrderStatus: order.status,
            ),
            TimelineStepWidget(
              status: OrderStatus.shipped,
              title: 'Order Shipped',
              subtitle: 'Your order is on the way',
              timestamp: order.shippedAt,
              isCompleted: order.status.index >= OrderStatus.shipped.index,
              currentOrderStatus: order.status,
            ),
            TimelineStepWidget(
              status: OrderStatus.delivered,
              title: 'Order Delivered',
              subtitle: 'Your order has been delivered successfully',
              timestamp: order.deliveredAt,
              isCompleted: order.status.index >= OrderStatus.delivered.index,
              currentOrderStatus: order.status,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}
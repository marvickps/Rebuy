import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../models/order_model.dart';

class ShippingInfoWidget extends StatelessWidget {
  final OrderModel order;

  const ShippingInfoWidget({
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
              'Shipping Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.truck, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Shipping Method: ${order.shippingMethodDisplayName}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (order.trackingNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.package, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking Number: ${order.trackingNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (order.shippingCarrier != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.building, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Carrier: ${order.shippingCarrier}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            if (order.shippedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.calendar, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Shipped: ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.shippedAt!)}',
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
}
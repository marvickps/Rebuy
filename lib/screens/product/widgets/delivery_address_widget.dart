import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/order_model.dart';

class DeliveryAddressWidget extends StatelessWidget {
  final OrderModel order;

  const DeliveryAddressWidget({
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
              order.deliveryAddress.isNotEmpty
                  ? order.deliveryAddress
                  : 'Address not provided',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
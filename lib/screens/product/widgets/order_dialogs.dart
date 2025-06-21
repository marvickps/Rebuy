// widgets/order_dialogs.dart
import 'package:flutter/material.dart';

class OrderDialogs {
  static Future<Map<String, String>?> showAddTrackingDialog(BuildContext context) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    return showDialog<Map<String, String>?>(
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carrierController,
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
            onPressed: () {
              if (trackingController.text.trim().isNotEmpty &&
                  carrierController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'trackingNumber': trackingController.text.trim(),
                  'carrier': carrierController.text.trim(),
                });
              }
            },
            child: const Text('Add Tracking'),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showConfirmDeliveryDialog(BuildContext context) async {
    return showDialog<bool>(
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
  }

  static Future<String?> showCancelOrderDialog(BuildContext context) async {
    final notesController = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
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
            onPressed: () {
              Navigator.pop(context, notesController.text.trim());
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
}
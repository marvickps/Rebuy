// lib/screens/product/widgets/order/order_actions_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/order_model.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/rating_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'order_dialogs.dart';
import 'rating_dialog.dart';

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
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<Map<String, bool>>(
      future: _checkRatingStatus(ratingProvider, authProvider.user?.uid),
      builder: (context, snapshot) {
        final ratingStatus = snapshot.data ?? {};

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

          // Seller can rate buyer after delivery
          if (order.status == OrderStatus.delivered &&
              ratingStatus['sellerCanRateBuyer'] == true) {
            buttons.add(
              OutlinedButton.icon(
                onPressed: () => _showRatingDialog(context, false), // false = rating buyer
                icon: const Icon(LucideIcons.star),
                label: const Text('Rate Buyer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber[700],
                  side: BorderSide(color: Colors.amber[700]!),
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

          // Buyer can rate seller after delivery
          if (order.status == OrderStatus.delivered &&
              ratingStatus['buyerCanRateSeller'] == true) {
            buttons.add(
              ElevatedButton.icon(
                onPressed: () => _showRatingDialog(context, true), // true = rating seller
                icon: const Icon(LucideIcons.star),
                label: const Text('Rate Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                ),
              ),
            );
          }
        }

        // Show already rated status
        if (order.status == OrderStatus.delivered) {
          if (isUserBuyer && ratingStatus['buyerHasRated'] == true) {
            buttons.add(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You rated this seller',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isUserSeller && ratingStatus['sellerHasRated'] == true) {
            buttons.add(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'You rated this buyer',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

        // Support/Contact button for delivered orders
        if (order.status == OrderStatus.delivered) {
          buttons.add(
            OutlinedButton.icon(
              onPressed: () => _showContactDialog(context),
              icon: const Icon(LucideIcons.messageCircle),
              label: const Text('Contact Support'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF078893),
                side: const BorderSide(color: Color(0xFF078893)),
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
      },
    );
  }

  Future<Map<String, bool>> _checkRatingStatus(RatingProvider ratingProvider, String? userId) async {
    if (userId == null || order.status != OrderStatus.delivered) {
      return {};
    }

    final buyerHasRated = await ratingProvider.hasUserRated(order.id, order.buyerId, true);
    final sellerHasRated = await ratingProvider.hasUserRated(order.id, order.sellerId, false);

    return {
      'buyerHasRated': buyerHasRated,
      'sellerHasRated': sellerHasRated,
      'buyerCanRateSeller': !buyerHasRated && userId == order.buyerId,
      'sellerCanRateBuyer': !sellerHasRated && userId == order.sellerId,
    };
  }

  Future<void> _showRatingDialog(BuildContext context, bool isRatingSeller) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        order: order,
        isRatingSeller: isRatingSeller,
      ),
    );

    if (result == true) {
      onRefresh();
    }
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

        // Show rating prompt after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            _showRatingPrompt(context);
          }
        });
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

          // Show rating prompt after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              _showRatingPrompt(context);
            }
          });
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

  void _showRatingPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.star, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('Rate Your Experience'),
          ],
        ),
        content: Text(
          isUserBuyer
              ? 'How was your experience with the seller? Your feedback helps other buyers make informed decisions.'
              : 'How was your experience with the buyer? Your feedback helps build trust in our community.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRatingDialog(context, isUserBuyer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.messageCircle, color: const Color(0xFF078893)),
            const SizedBox(width: 8),
            const Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help with your order? Choose an option:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.messageSquare, color: Colors.blue[600]),
              title: const Text('Report an Issue'),
              subtitle: const Text('Report problems with the order'),
              onTap: () {
                Navigator.of(context).pop();
                _reportIssue(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.phone, color: Colors.green[600]),
              title: const Text('Contact Customer Service'),
              subtitle: const Text('Get help from our support team'),
              onTap: () {
                Navigator.of(context).pop();
                _contactCustomerService(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    // Navigate to issue reporting screen or show form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue reporting feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _contactCustomerService(BuildContext context) {
    // Navigate to customer service or show contact details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer service contact feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
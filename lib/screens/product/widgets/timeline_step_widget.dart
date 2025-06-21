import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:rebuy/screens/product/widgets/utils/order_utils.dart';
import '../../../models/order_model.dart';


class TimelineStepWidget extends StatelessWidget {
  final OrderStatus status;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final bool isCompleted;
  final OrderStatus currentOrderStatus;
  final bool isLast;

  const TimelineStepWidget({
    super.key,
    required this.status,
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.isCompleted,
    required this.currentOrderStatus,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = currentOrderStatus == status;

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
                    ? OrderUtils.getStatusColor(status)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? LucideIcons.check : OrderUtils.getStatusIcon(status),
                size: 12,
                color: isCompleted ? Colors.white : Colors.grey[600],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? OrderUtils.getStatusColor(status) : Colors.grey[300],
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
                  DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp!),
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
}

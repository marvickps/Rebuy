import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/order_model.dart';


class OrderUtils {
  static Color getStatusColor(OrderStatus status) {
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

  static IconData getStatusIcon(OrderStatus status) {
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
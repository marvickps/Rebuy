import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../models/offer_model.dart';
import '../payment.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isSentOffer;
  final Function(String) onAction;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isSentOffer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(offer.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _getStatusIcon(offer.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getOfferTypeText(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        offer.statusDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(offer.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (offer.isCounterOffer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Counter Offer',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: offer.productImageUrl.isNotEmpty
                      ? Image.network(
                          offer.productImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(
                                LucideIcons.image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(
                            LucideIcons.image,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getParticipantText(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Listed: ₹${offer.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${offer.offerAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF078893),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.trendingDown,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.discountPercentage.toStringAsFixed(1)}% off',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message (if any)
          if (offer.message != null && offer.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Message:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(offer.message!, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),

          // Time and Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Info
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(offer.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (offer.status == OfferStatus.pending)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.timer,
                            size: 14,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${_formatDateTime(offer.expiresAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Action Buttons - Updated Logic
                if (_shouldShowActions())
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildActionButtons(),
                  ),

                // Status Messages
                if (offer.status == OfferStatus.accepted)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildAcceptedStatusWidget(context),
                  ),

                if (offer.status == OfferStatus.rejected)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.xCircle,
                            color: Colors.red[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getRejectionText(),
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (offer.status == OfferStatus.countered)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.arrowLeftRight,
                            color: Colors.orange[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getCounteredText(),
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to determine if actions should be shown
  bool _shouldShowActions() {
    if (offer.status != OfferStatus.pending) return false;

    // For regular offers: show actions only for received offers
    if (!offer.isCounterOffer) {
      return !isSentOffer;
    }

    // For counter offers: show actions based on who made the counter offer
    // If it's in sent offers but it's a counter offer from seller, buyer should see actions
    // If it's in received offers but it's a counter offer from buyer, seller should see actions
    return true;
  }

  // Helper method to build action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onAction('reject'),
            icon: const Icon(LucideIcons.x, size: 16),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onAction('counter'),
            icon: const Icon(LucideIcons.arrowLeftRight, size: 16),
            label: const Text('Counter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onAction('accept'),
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              textStyle: const TextStyle(fontSize: 14),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build accepted status widget with payment action
  Widget _buildAcceptedStatusWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: Colors.green[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAcceptedText(),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handlePaymentAction(context),
              icon: const Icon(LucideIcons.creditCard, size: 16),
              label: Text(_getPaymentButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF078893),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle payment action
  void _handlePaymentAction(BuildContext context) {
    if (isSentOffer) {
      // Buyer should proceed to payment
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen(offer: offer)),
      );
    } else {
      // Seller should send payment request or generate delivery receipt
      _showSellerOptions(context);
    }
  }

  // Show seller options after offer acceptance
  void _showSellerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Offer Accepted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The buyer has accepted your offer of ₹${offer.offerAmount.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to payment request or order management
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment request sent to buyer'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.send),
                label: const Text('Send Payment Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078893),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to delivery preparation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Prepare item for delivery once payment is confirmed',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.package),
                label: const Text('Prepare for Delivery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods for text content
  String _getOfferTypeText() {
    if (offer.isCounterOffer) {
      return isSentOffer
          ? 'Counter Offer from Seller'
          : 'Counter Offer from Buyer';
    }
    return isSentOffer ? 'Offer Sent' : 'Offer Received';
  }

  String _getParticipantText() {
    if (offer.isCounterOffer) {
      return isSentOffer
          ? 'From: ${offer.sellerName}'
          : 'From: ${offer.buyerName}';
    }
    return isSentOffer ? 'To: ${offer.sellerName}' : 'From: ${offer.buyerName}';
  }

  String _getAcceptedText() {
    if (offer.isCounterOffer) {
      return isSentOffer
          ? 'Counter offer accepted! 🎉'
          : 'You accepted the counter offer! 🎉';
    }
    return isSentOffer
        ? 'Your offer has been accepted! 🎉'
        : 'You accepted this offer! 🎉';
  }

  String _getRejectionText() {
    if (offer.isCounterOffer) {
      return isSentOffer
          ? 'Counter offer was rejected'
          : 'You rejected the counter offer';
    }
    return isSentOffer ? 'Your offer was rejected' : 'You rejected this offer';
  }

  String _getCounteredText() {
    if (offer.isCounterOffer) {
      return 'This offer has been countered';
    }
    return isSentOffer
        ? 'Seller made a counter offer'
        : 'You made a counter offer';
  }

  String _getPaymentButtonText() {
    // If this is a sent offer (buyer's perspective) and it's accepted, buyer should pay
    // If this is a received offer (seller's perspective) and it's accepted, seller should request payment
    if (isSentOffer) {
      return 'Proceed to Payment';
    } else {
      return 'Manage Order';
    }
  }

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return Colors.orange;
      case OfferStatus.accepted:
        return Colors.green;
      case OfferStatus.rejected:
        return Colors.red;
      case OfferStatus.countered:
        return Colors.orange;
      case OfferStatus.expired:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return Icon(
          LucideIcons.clock,
          color: _getStatusColor(status),
          size: 16,
        );
      case OfferStatus.accepted:
        return Icon(
          LucideIcons.checkCircle,
          color: _getStatusColor(status),
          size: 16,
        );
      case OfferStatus.rejected:
        return Icon(
          LucideIcons.xCircle,
          color: _getStatusColor(status),
          size: 16,
        );
      case OfferStatus.countered:
        return Icon(
          LucideIcons.arrowLeftRight,
          color: _getStatusColor(status),
          size: 16,
        );
      case OfferStatus.expired:
        return Icon(
          LucideIcons.alarmClockOff,
          color: _getStatusColor(status),
          size: 16,
        );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

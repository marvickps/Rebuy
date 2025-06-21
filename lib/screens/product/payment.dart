import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';
import 'order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OfferModel offer;
  final UserModel? sellerInfo; // Seller's user info containing UPI ID

  const PaymentScreen({
    super.key,
    required this.offer,
    this.sellerInfo,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'upi';
  bool isGeneratingQR = false;
  String? generatedQRData;
  bool isProcessingPayment = false;
  UserModel? sellerInfo;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'upi',
      'name': 'UPI Payment',
      'icon': LucideIcons.smartphone,
      'description': 'Pay using UPI apps like PhonePe, Paytm, GPay',
    },
    {
      'id': 'cod',
      'name': 'Cash on Delivery',
      'icon': LucideIcons.banknote,
      'description': 'Pay when you receive the item',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    if (widget.sellerInfo != null) {
      sellerInfo = widget.sellerInfo;
      _generateQRCode(); // Auto-generate QR if seller info is available
    } else {
      // Load seller info from Firestore if not provided
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.offer.sellerId)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            sellerInfo = UserModel.fromMap(doc.data()!);
          });
          _generateQRCode(); // Auto-generate QR after loading seller info
        }
      } catch (e) {
        print('Error loading seller info: $e');
      }
    }
  }

  void _generateQRCode() {
    if (sellerInfo?.upiId.isEmpty ?? true) return;

    setState(() {
      isGeneratingQR = true;
    });

    // Simulate QR generation delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isGeneratingQR = false;
          generatedQRData = _generateUPIString();
        });
      }
    });
  }

  String _generateUPIString() {
    final sellerUPI = sellerInfo?.upiId ?? '';
    final amount = widget.offer.offerAmount;
    final productTitle = widget.offer.productTitle.replaceAll(' ', '%20');
    final sellerName = widget.offer.sellerName.replaceAll(' ', '%20');

    // Fixed UPI URL format
    return 'upi://pay?pa=$sellerUPI&pn=$sellerName&am=$amount&cu=INR&tn=Payment%20for%20$productTitle&tr=${widget.offer.id}';
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == 'upi' && generatedQRData != null) {
      await _handleUPIPayment();
    } else {
      _showMockPaymentSuccess();
    }
  }

  Future<void> _handleUPIPayment() async {
    try {
      setState(() {
        isProcessingPayment = true;
      });

      // Try multiple UPI URL schemes for better compatibility
      final upiUrls = [
        generatedQRData!, // Standard UPI URL
        'paytmmp://pay?pa=${sellerInfo?.upiId}&pn=${widget.offer.sellerName.replaceAll(' ', '%20')}&am=${widget.offer.offerAmount}&cu=INR', // Paytm
        'phonepe://pay?pa=${sellerInfo?.upiId}&pn=${widget.offer.sellerName.replaceAll(' ', '%20')}&am=${widget.offer.offerAmount}&cu=INR', // PhonePe
        'gpay://upi/pay?pa=${sellerInfo?.upiId}&pn=${widget.offer.sellerName.replaceAll(' ', '%20')}&am=${widget.offer.offerAmount}&cu=INR', // Google Pay
      ];

      bool launched = false;

      for (String upiUrl in upiUrls) {
        try {
          final Uri upiUri = Uri.parse(upiUrl);
          if (await canLaunchUrl(upiUri)) {
            await launchUrl(upiUri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          print('Failed to launch $upiUrl: $e');
          continue;
        }
      }

      if (launched) {
        // Show payment confirmation dialog after launching UPI app
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500)); // Small delay
          _showUPIPaymentConfirmationDialog();
        }
      } else {
        // Fallback: show QR code for manual scanning
        _showQRCodeDialog();
      }
    } catch (e) {
      print('Error launching UPI: $e');
      _showQRCodeDialog();
    } finally {
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  void _showUPIPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Status'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.smartphone, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'UPI app has been opened for payment.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please complete the payment and confirm below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmPaymentSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Payment Done'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: generatedQRData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan this QR code with your UPI app to make payment',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmPaymentSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Payment Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPaymentSuccess() async {
    try {
      // Update offer status to paid in Firestore
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.id)
          .update({
        'status': OfferStatus.paid.name,
        'paidAt': Timestamp.now(),
        'transactionId': 'TXN_${widget.offer.id}_${DateTime.now().millisecondsSinceEpoch}',
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        _showPaymentSuccessDialog();
      }
    } catch (e) {
      print('Error updating payment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating payment status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Payment Successful!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your payment has been processed successfully.'),
            SizedBox(height: 8),
            Text('The seller will be notified and will proceed with shipping.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to offers screen
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => OrderTrackingScreen(),
              //   ),
              // );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078893),
              foregroundColor: Colors.white,
            ),
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  void _showMockPaymentSuccess() {
    // For COD, just mark as accepted and navigate
    _confirmPaymentSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF078893),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Payment Methods
            _buildPaymentMethods(),
            const SizedBox(height: 24),

            // Payment Details based on selected method
            if (selectedPaymentMethod == 'upi') _buildUPIPayment(),
            if (selectedPaymentMethod == 'cod') _buildCODPayment(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.offer.productImageUrl.isNotEmpty
                      ? Image.network(
                    widget.offer.productImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.image),
                      );
                    },
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(LucideIcons.image),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.offer.productTitle,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sold by: ${widget.offer.sellerName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Item Price:'),
                Text(
                  '₹${widget.offer.originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offer Price:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${widget.offer.offerAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF078893),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You Save:',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${(widget.offer.originalPrice - widget.offer.offerAmount).toStringAsFixed(0)} (${widget.offer.discountPercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.map((method) {
              return RadioListTile<String>(
                value: method['id'],
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                    if (value == 'upi' && sellerInfo?.upiId.isNotEmpty == true) {
                      _generateQRCode();
                    } else {
                      generatedQRData = null;
                    }
                  });
                },
                title: Row(
                  children: [
                    Icon(method['icon'], size: 20),
                    const SizedBox(width: 8),
                    Text(method['name']),
                  ],
                ),
                subtitle: Text(
                  method['description'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                activeColor: const Color(0xFF078893),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIPayment() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPI Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Seller UPI Info Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.user, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment to: ${widget.offer.sellerName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UPI ID: ${sellerInfo?.upiId ?? 'Loading...'}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (sellerInfo?.upiId.isEmpty ?? true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Seller has not configured UPI ID yet. Please contact seller or choose Cash on Delivery.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (generatedQRData != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: QrImageView(
                            data: generatedQRData!,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan with any UPI app',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessingPayment ? null : _processPayment,
                    icon: isProcessingPayment
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(LucideIcons.creditCard),
                    label: Text(
                      isProcessingPayment
                          ? 'Opening UPI App...'
                          : 'Pay ₹${widget.offer.offerAmount.toStringAsFixed(0)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ] else if (isGeneratingQR) ...[
                const SizedBox(height: 24),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating payment QR code...'),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCODPayment() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash on Delivery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will pay ₹${widget.offer.offerAmount.toStringAsFixed(0)} when the item is delivered to you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(LucideIcons.banknote),
                label: const Text('Place Order (COD)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/offer_model.dart';

class PaymentScreen extends StatefulWidget {
  final OfferModel offer;

  const PaymentScreen({super.key, required this.offer});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'upi';
  final TextEditingController upiIdController = TextEditingController();
  bool isGeneratingQR = false;
  String? generatedQRData;

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
  void dispose() {
    upiIdController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    setState(() {
      isGeneratingQR = true;
    });

    // Simulate QR generation delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isGeneratingQR = false;
          // Generate UPI payment string
          generatedQRData = _generateUPIString();
        });
      }
    });
  }

  String _generateUPIString() {
    final sellerUPI = upiIdController.text.trim();
    final amount = widget.offer.offerAmount;
    final productTitle = widget.offer.productTitle;

    return 'upi://pay?pa=$sellerUPI&pn=${widget.offer.sellerName}&am=$amount&cu=INR&tn=Payment for $productTitle';
  }

  void _processPayment() {
    if (selectedPaymentMethod == 'upi' && generatedQRData != null) {
      _showPaymentConfirmationDialog();
    } else {
      _showMockPaymentSuccess();
    }
  }

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan the QR code with your UPI app to complete the payment.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Once payment is successful, click "I have paid" button.',
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
              _showMockPaymentSuccess();
            },
            child: const Text('I have paid'),
          ),
        ],
      ),
    );
  }

  void _showMockPaymentSuccess() {
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
              // TODO: Navigate to order tracking screen
            },
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
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
                    generatedQRData = null; // Reset QR when method changes
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
            TextField(
              controller: upiIdController,
              decoration: const InputDecoration(
                labelText: 'Seller\'s UPI ID',
                hintText: 'Enter seller\'s UPI ID (e.g., seller@paytm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.atSign),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: upiIdController.text.trim().isEmpty
                    ? null
                    : _generateQRCode,
                icon: isGeneratingQR
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.qrCode),
                label: Text(
                  isGeneratingQR ? 'Generating QR...' : 'Generate QR Code',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078893),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
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
                      QrImageView(
                        data: generatedQRData!,
                        version: QrVersions.auto,
                        size: 200.0,
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
                  onPressed: _processPayment,
                  icon: const Icon(LucideIcons.creditCard),
                  label: Text(
                    'Pay ₹${widget.offer.offerAmount.toStringAsFixed(0)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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

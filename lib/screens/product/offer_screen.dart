import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/offer_provider.dart';
import '../../providers/auth_provider.dart';

class MakeOfferScreen extends StatefulWidget {
  final ProductModel product;

  const MakeOfferScreen({
    super.key,
    required this.product,
  });

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offerController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _calculateDiscount(double originalPrice, double offerPrice) {
    if (originalPrice == 0) return '0%';
    final discount = ((originalPrice - offerPrice) / originalPrice) * 100;
    return '${discount.toStringAsFixed(1)}%';
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make an offer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final offerAmount = double.parse(_offerController.text);
      final message = _messageController.text.trim();

      final offerId = await offerProvider.createOffer(
        product: widget.product,
        buyer: authProvider.userModel!,
        offerAmount: offerAmount,
        message: message.isEmpty ? null : message,
      );

      if (offerId != null) {
        // Show success dialog
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(offerProvider.errorMessage ?? 'Failed to create offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          LucideIcons.checkCircle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Offer Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your offer of ₹${_offerController.text} has been sent to ${widget.product.sellerName}.'),
            const SizedBox(height: 8),
            const Text(
              'You will be notified when the seller responds to your offer.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to product detail
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make an Offer'),
        backgroundColor: const Color(0xFF002F34),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product.imageUrls.isNotEmpty
                            ? Image.network(
                          widget.product.imageUrls.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(LucideIcons.image, color: Colors.grey),
                            );
                          },
                        )
                            : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(LucideIcons.image, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Listed Price: ₹${widget.product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002F34),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seller: ${widget.product.sellerName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Offer Amount Section
              const Text(
                'Your Offer Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _offerController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Enter your offer amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 15000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an offer amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount >= widget.product.price) {
                    return 'Offer must be less than listed price';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Rebuild to update discount calculation
                },
              ),

              // Discount Calculation
              if (_offerController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.trendingDown, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Discount: ${_calculateDiscount(widget.product.price, double.tryParse(_offerController.text) ?? 0)}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Message Section
              const Text(
                'Message (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Add a message to your offer',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., I can pick up immediately, or explain why you\'re interested...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Important Notes
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoPoint('• Your offer will be valid for 7 days'),
                      _buildInfoPoint('• The seller can accept, reject, or counter your offer'),
                      _buildInfoPoint('• You\'ll be notified of any response'),
                      _buildInfoPoint('• You can only have one active offer per product'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002F34),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Send Offer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[700],
        ),
      ),
    );
  }
}
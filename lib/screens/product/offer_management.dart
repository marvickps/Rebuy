import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/offer_model.dart';
import '../../providers/offer_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/offer_card.dart';
import 'widgets/counter_offer_dialog.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    if (authProvider.user != null) {
      setState(() {
        _isLoading = true;
      });

      await offerProvider.loadUserOffers(authProvider.user!.uid);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOffers() async {
    await _loadOffers();
  }

  Future<void> _handleOfferAction(OfferModel offer, String action) async {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    bool success = false;

    switch (action) {
      case 'accept':
        success = await offerProvider.acceptOffer(offer.id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: Navigate to payment or order confirmation
        }
        break;

      case 'reject':
        success = await _showRejectDialog(offer);
        break;

      case 'counter':
        success = await _showCounterOfferDialog(offer);
        break;
    }

    if (success) {
      _refreshOffers();
    } else if (offerProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(offerProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showRejectDialog(OfferModel offer) async {
    final TextEditingController reasonController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject the offer of ₹${offer.offerAmount.toStringAsFixed(0)}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Let the buyer know why you rejected the offer...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final offerProvider = Provider.of<OfferProvider>(context, listen: false);
              final success = await offerProvider.rejectOffer(
                offer.id,
                reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              );
              Navigator.of(context).pop(success);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    reasonController.dispose();
    return result ?? false;
  }

  Future<bool> _showCounterOfferDialog(OfferModel offer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CounterOfferDialog(offer: offer),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
        backgroundColor: const Color(0xFF002F34),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sent Offers'),
            Tab(text: 'Received Offers'),
          ],
        ),
      ),
      body: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Sent Offers Tab
              _buildOffersTab(
                offers: offerProvider.sentOffers,
                emptyMessage: 'You haven\'t made any offers yet',
                emptyIcon: LucideIcons.send,
                isSentOffers: true,
              ),

              // Received Offers Tab
              _buildOffersTab(
                offers: offerProvider.receivedOffers,
                emptyMessage: 'No offers received yet',
                emptyIcon: LucideIcons.inbox,
                isSentOffers: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersTab({
    required List<OfferModel> offers,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isSentOffers,
  }) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (isSentOffers) ...[
              const SizedBox(height: 8),
              const Text(
                'Browse products and make offers to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return OfferCard(
            offer: offer,
            isSentOffer: isSentOffers,
            onAction: (action) => _handleOfferAction(offer, action),
          );
        },
      ),
    );
  }
}
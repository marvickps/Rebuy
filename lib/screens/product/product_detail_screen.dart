import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';

import '../../providers/offer_provider.dart';
import './offer_screen.dart';
import './offer_management.dart';

import 'widgets/image_carousel.dart';
import 'widgets/product_card.dart';
import 'add_product_screen.dart';
import '../chat/screen/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final ProductModel? product; // Optional, for faster loading

  const ProductDetailScreen({super.key, required this.productId, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  bool _hasExistingOffer = false;
  double? _existingOfferAmount;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      // Use provided product or fetch from Firebase
      ProductModel? product = widget.product;
      if (product == null || product.id != widget.productId) {
        product = await productProvider.getProduct(widget.productId);
      }

      if (product != null) {
        setState(() {
          _product = product;
        });

        // Check if product is in favorites
        if (authProvider.userModel != null) {
          setState(() {
            _isFavorite = authProvider.userModel!.favorites.contains(
              product!.id,
            );
          });
        }

        await _checkExistingOffer(authProvider.user!.uid, product.id);
        // Load related products
        final relatedProducts = await productProvider.getRelatedProducts(
          product.id,
          product.category,
          limit: 4,
        );

        setState(() {
          _relatedProducts = relatedProducts;
        });
      }
    } catch (e) {
      print('Error loading product details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall() async {
    if (_product?.sellerPhone != null && _product!.sellerPhone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: _product!.sellerPhone);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          throw 'Could not launch phone dialer';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot make phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkExistingOffer(String userId, String productId) async {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    try {
      // Load user's sent offers
      await offerProvider.loadUserOffers(userId);

      // Check if there's an existing offer for this product
      final existingOffer = offerProvider.sentOffers.firstWhere(
        (offer) =>
            offer.productId == productId &&
            (offer.status == 'pending' || offer.status == 'counter'),
        orElse: () => throw StateError('No offer found'),
      );

      setState(() {
        _hasExistingOffer = true;
        _existingOfferAmount = existingOffer.offerAmount;
      });
    } catch (e) {
      // No existing offer found, which is fine
      setState(() {
        _hasExistingOffer = false;
        _existingOfferAmount = null;
      });
    }
  }

  Future<void> _navigateToMakeOffer() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in
    if (authProvider.user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_product == null) return;

    // Check if user is trying to make offer on their own product
    if (authProvider.user!.uid == _product!.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot make an offer on your own product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to make offer screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeOfferScreen(product: _product!),
      ),
    );

    // Refresh offer status if an offer was made
    if (result == true) {
      await _checkExistingOffer(authProvider.user!.uid, _product!.id);
    }
  }

  Future<void> _navigateToOfferManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OffersScreen()),
    );

    // Refresh offer status when returning
    if (result == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null && _product != null) {
        await _checkExistingOffer(authProvider.user!.uid, _product!.id);
      }
    }
  }

  Future<void> _showOfferOptions() async {
    if (_hasExistingOffer) {
      // Show existing offer options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Your Offer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have an existing offer of ₹${_existingOfferAmount?.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.eye, color: Colors.blue),
                title: const Text('View All My Offers'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToOfferManagement();
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.edit, color: Colors.orange),
                title: const Text('Make New Offer'),
                subtitle: const Text('This will replace your existing offer'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToMakeOffer();
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Directly navigate to make offer
      _navigateToMakeOffer();
    }
  }

  Future<void> _startChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if user is logged in
    if (authProvider.user == null || authProvider.userModel == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_product == null) return;

    // Check if user is trying to chat with themselves
    if (authProvider.user!.uid == _product!.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get seller user model
      UserModel? sellerUser = await userProvider.getUser(_product!.sellerId);

      if (sellerUser == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller information not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create or get existing chat
      final chatId = await chatProvider.createOrGetChat(
        product: _product!,
        buyer: authProvider.userModel!,
        seller: sellerUser,
      );

      Navigator.pop(context); // Close loading dialog

      if (chatId != null) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              productTitle: _product!.title,
              otherUserName: sellerUser.name,
              productImageUrl: _product!.imageUrls.isNotEmpty
                  ? _product!.imageUrls.first
                  : null,
              productPrice: _product!.price,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${chatProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareProduct() async {
    if (_product != null) {
      final String shareText =
          '''
      ${_product!.title}
      
      ₹${_product!.price.toStringAsFixed(0)}
      ${_product!.description}
      
      Location: ${_product!.location}
      Condition: ${_product!.conditionDisplayName}
      
      Contact: ${_product!.sellerPhone}
      ''';

      try {
        await Share.share(shareText, subject: _product!.title);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot share product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditDeleteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(product: _product),
                  ),
                ).then((_) => _loadProductDetails());
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.banknote, color: Colors.blue),
              title: const Text('View Offers'),
              onTap: () {
                Navigator.pop(context);
                _navigateToOfferManagement();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text(
                'Delete Product',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final productProvider = Provider.of<ProductProvider>(
                context,
                listen: false,
              );
              final success = await productProvider.deleteProduct(_product!.id);

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete product: ${productProvider.errorMessage}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Contact ${_product!.sellerName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_product!.sellerPhone),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.messageCircle,
                color: Colors.orange,
              ),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                _startChat();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.phone, color: Colors.green),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?.uid == _product?.sellerId;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.alertCircle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Product not found', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // App Bar with Image Carousel
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _product!.imageUrls.isNotEmpty
                        ? ImageCarousel(
                            imageUrls: _product!.imageUrls,
                            height: 300,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                LucideIcons.image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: _shareProduct,
                      icon: const Icon(LucideIcons.share),
                    ),
                    if (isOwner)
                      IconButton(
                        onPressed: _showEditDeleteOptions,
                        icon: const Icon(LucideIcons.moreVertical),
                      ),
                  ],
                ),

                // Product Details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price and Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${_product!.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF078893),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _product!.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Existing offer notification
                        if (_hasExistingOffer && !isOwner)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.banknote,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You have an offer of ₹${_existingOfferAmount?.toStringAsFixed(0)} on this product',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _navigateToOfferManagement,
                                  child: const Text('View'),
                                ),
                              ],
                            ),
                          ),
                        // Category and Condition
                        Row(
                          children: [
                            Chip(
                              label: Text(_product!.categoryDisplayName),
                              backgroundColor: Colors.blue[50],
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(_product!.conditionDisplayName),
                              backgroundColor: Colors.green[50],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Tags
                        if (_product!.tags.isNotEmpty) ...[
                          const Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _product!.tags.map((tag) {
                              return Chip(
                                label: Text('#$tag'),
                                backgroundColor: Colors.grey[200],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Location and Posted Time
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _product!.location,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Posted ${_getTimeAgo(_product!.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.eye, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_product!.views} views',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Seller Info
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seller Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: Text(
                                        _product!.sellerName.isNotEmpty
                                            ? _product!.sellerName[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _product!.sellerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // TODO: Add seller rating when available
                                          Text(
                                            'Member since ${_getTimeAgo(_product!.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isOwner)
                                      ElevatedButton(
                                        onPressed: _showContactOptions,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF078893,
                                          ),
                                        ),
                                        child: const Text('Contact'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Related Products
                        if (_relatedProducts.isNotEmpty) ...[
                          const Text(
                            'Related Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _relatedProducts.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: ProductCard(
                                    product: _relatedProducts[index],
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailScreen(
                                                productId:
                                                    _relatedProducts[index].id,
                                                product:
                                                    _relatedProducts[index],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _product == null || isOwner
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToMakeOffer();
                      },
                      icon: const Icon(
                        LucideIcons.banknote,
                        color: Color(0xFF078893),
                      ),
                      label: Text(
                        'Make an Offer',
                        style: TextStyle(color: Color(0xFF078893)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startChat,
                      icon: const Icon(LucideIcons.messageCircle),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF078893),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

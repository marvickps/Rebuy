// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:carousel_slider/carousel_slider.dart'
//     as carousel
//     hide CarouselController;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart';

// import '../../models/product_model.dart';
// import '../../models/user_model.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/product_provider.dart';
// import '../../providers/chat_provider.dart';
// import '../../providers/user_provider.dart';

// class ProductDetailScreen extends StatefulWidget {
//   final String? productId;
//   final ProductModel? product;

//   const ProductDetailScreen({super.key, this.productId, this.product});

//   @override
//   State<ProductDetailScreen> createState() => _ProductDetailScreenState();
// }

// class _ProductDetailScreenState extends State<ProductDetailScreen> {
//   ProductModel? _product;
//   UserModel? _seller;
//   bool _isLoading = true;
//   int _currentImageIndex = 0;
//   final carousel.CarouselController _carouselController =
//       carousel.CarouselControlle2r();

//   @override
//   void initState() {
//     super.initState();
//     _loadProductData();
//   }

//   Future<void> _loadProductData() async {
//     setState(() => _isLoading = true);

//     try {
//       if (widget.product != null) {
//         _product = widget.product;
//       } else if (widget.productId != null) {
//         final productProvider = Provider.of<ProductProvider>(
//           context,
//           listen: false,
//         );
//         _product = await productProvider.getProduct(widget.productId!);
//       }

//       if (_product != null) {
//         final userProvider = Provider.of<UserProvider>(context, listen: false);
//         _seller = await userProvider.getUser(_product!.sellerId);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading product: ${e.toString()}')),
//       );
//     }

//     setState(() => _isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Product Details')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_product == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Product Details')),
//         body: const Center(child: Text('Product not found')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: CustomScrollView(
//         slivers: [
//           _buildSliverAppBar(),
//           SliverToBoxAdapter(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildProductInfo(),
//                 const SizedBox(height: 12),
//                 _buildSellerInfo(),
//                 const SizedBox(height: 12),
//                 _buildDescription(),
//                 const SizedBox(height: 12),
//                 _buildProductDetails(),
//                 const SizedBox(height: 100), // Space for floating buttons
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: _buildFloatingActionButtons(),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }

//   Widget _buildSliverAppBar() {
//     return SliverAppBar(
//       expandedHeight: 300,
//       pinned: true,
//       backgroundColor: Theme.of(context).primaryColor,
//       actions: [
//         Consumer<AuthProvider>(
//           builder: (context, authProvider, child) {
//             if (authProvider.userModel == null) return const SizedBox();

//             final isFavorite = authProvider.isFavorite(_product!.id);
//             return IconButton(
//               onPressed: () {
//                 if (isFavorite) {
//                   authProvider.removeFromFavorites(_product!.id);
//                 } else {
//                   authProvider.addToFavorites(_product!.id);
//                 }
//               },
//               icon: Icon(
//                 isFavorite ? Icons.favorite : Icons.favorite_border,
//                 color: isFavorite ? Colors.red : Colors.white,
//               ),
//             );
//           },
//         ),
//         IconButton(onPressed: _shareProduct, icon: const Icon(Icons.share)),
//       ],
//       flexibleSpace: FlexibleSpaceBar(background: _buildImageCarousel()),
//     );
//   }

//   Widget _buildImageCarousel() {
//     if (_product!.imageUrls.isEmpty) {
//       return Container(
//         color: Colors.grey[300],
//         child: const Center(
//           child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
//         ),
//       );
//     }

//     return Stack(
//       children: [
//         carousel.CarouselSlider(
//           carouselController: _carouselController,
//           options: carousel.CarouselOptions(
//             height: double.infinity,
//             viewportFraction: 1.0,
//             enableInfiniteScroll: _product!.imageUrls.length > 1,
//             onPageChanged: (index, reason) {
//               setState(() => _currentImageIndex = index);
//             },
//           ),
//           items: _product!.imageUrls.map((imageUrl) {
//             return Builder(
//               builder: (BuildContext context) {
//                 return GestureDetector(
//                   onTap: () => _showImageFullScreen(imageUrl),
//                   child: Container(
//                     width: MediaQuery.of(context).size.width,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         image: NetworkImage(imageUrl),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           }).toList(),
//         ),
//         if (_product!.imageUrls.length > 1)
//           Positioned(
//             bottom: 16,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: _product!.imageUrls.asMap().entries.map((entry) {
//                 return Container(
//                   width: 8,
//                   height: 8,
//                   margin: const EdgeInsets.symmetric(horizontal: 4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _currentImageIndex == entry.key
//                         ? Colors.white
//                         : Colors.white.withOpacity(0.4),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildProductInfo() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '₹${NumberFormat('#,##,###').format(_product!.price)}',
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.green,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _product!.title,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
//               const SizedBox(width: 4),
//               Text(
//                 _product!.location,
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//               const Spacer(),
//               Text(
//                 _formatDate(_product!.createdAt),
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   _product!.categoryDisplayName,
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getConditionColor(
//                     _product!.condition,
//                   ).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   _product!.conditionDisplayName,
//                   style: TextStyle(
//                     color: _getConditionColor(_product!.condition),
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
//               const SizedBox(width: 4),
//               Text(
//                 '${_product!.views} views',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSellerInfo() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Seller Information',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.grey[300],
//                 backgroundImage: _seller?.profileImageUrl.isNotEmpty == true
//                     ? NetworkImage(_seller!.profileImageUrl)
//                     : null,
//                 child: _seller?.profileImageUrl.isEmpty == true
//                     ? Text(
//                         _seller?.name.substring(0, 1).toUpperCase() ?? 'U',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       )
//                     : null,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _seller?.name ?? _product!.sellerName,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     if (_seller != null)
//                       Consumer<UserProvider>(
//                         builder: (context, userProvider, child) {
//                           final status = userProvider.getOnlineStatus(
//                             _seller!.uid,
//                           );
//                           return Text(
//                             status,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: status == 'Online'
//                                   ? Colors.green
//                                   : Colors.grey[600],
//                             ),
//                           );
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//               Consumer<AuthProvider>(
//                 builder: (context, authProvider, child) {
//                   if (authProvider.userModel?.uid == _product!.sellerId) {
//                     return const SizedBox();
//                   }
//                   return TextButton(
//                     onPressed: () => _viewSellerProfile(),
//                     child: const Text('View Profile'),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDescription() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Description',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _product!.description,
//             style: const TextStyle(fontSize: 14, height: 1.5),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductDetails() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Product Details',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 12),
//           _buildDetailRow('Category', _product!.categoryDisplayName),
//           _buildDetailRow('Condition', _product!.conditionDisplayName),
//           _buildDetailRow('Posted on', _formatDate(_product!.createdAt)),
//           if (_product!.tags.isNotEmpty)
//             _buildDetailRow('Tags', _product!.tags.join(', ')),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: TextStyle(color: Colors.grey[600], fontSize: 14),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFloatingActionButtons() {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         if (authProvider.userModel == null) {
//           return FloatingActionButton.extended(
//             onPressed: () => Navigator.pushNamed(context, '/login'),
//             label: const Text('Login to Contact'),
//             icon: const Icon(Icons.login),
//           );
//         }

//         if (authProvider.userModel!.uid == _product!.sellerId) {
//           return Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               FloatingActionButton.extended(
//                 heroTag: "edit",
//                 onPressed: _editProduct,
//                 label: const Text('Edit'),
//                 icon: const Icon(Icons.edit),
//                 backgroundColor: Colors.orange,
//               ),
//               FloatingActionButton.extended(
//                 heroTag: "delete",
//                 onPressed: _deleteProduct,
//                 label: const Text('Delete'),
//                 icon: const Icon(Icons.delete),
//                 backgroundColor: Colors.red,
//               ),
//             ],
//           );
//         }

//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             FloatingActionButton.extended(
//               heroTag: "call",
//               onPressed: _callSeller,
//               label: const Text('Call'),
//               icon: const Icon(Icons.phone),
//               backgroundColor: Colors.green,
//             ),
//             FloatingActionButton.extended(
//               heroTag: "chat",
//               onPressed: _chatWithSeller,
//               label: const Text('Chat'),
//               icon: const Icon(Icons.chat),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showImageFullScreen(String imageUrl) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => Scaffold(
//           backgroundColor: Colors.black,
//           appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
//           body: Center(
//             child: InteractiveViewer(
//               child: Image.network(
//                 imageUrl,
//                 fit: BoxFit.contain,
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return const Center(child: CircularProgressIndicator());
//                 },
//                 errorBuilder: (context, error, stackTrace) {
//                   return const Center(
//                     child: Icon(Icons.error, color: Colors.white, size: 64),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _callSeller() async {
//     final phoneUrl = Uri.parse('tel:${_product!.sellerPhone}');
//     if (await canLaunchUrl(phoneUrl)) {
//       await launchUrl(phoneUrl);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not launch phone app')),
//       );
//     }
//   }

//   Future<void> _chatWithSeller() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final chatProvider = Provider.of<ChatProvider>(context, listen: false);
//     final userProvider = Provider.of<UserProvider>(context, listen: false);

//     if (authProvider.userModel == null || _seller == null) return;

//     try {
//       final chatId = await chatProvider.createOrGetChat(
//         product: _product!,
//         buyer: authProvider.userModel!,
//         seller: _seller!,
//       );

//       if (chatId != null) {
//         Navigator.pushNamed(context, '/chat', arguments: {'chatId': chatId});
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error starting chat: ${e.toString()}')),
//       );
//     }
//   }

//   void _shareProduct() {
//     // Implement share functionality
//     // You can use the share_plus package for this
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Share functionality coming soon')),
//     );
//   }

//   void _viewSellerProfile() {
//     Navigator.pushNamed(
//       context,
//       '/profile',
//       arguments: {'userId': _seller!.uid},
//     );
//   }

//   void _editProduct() {
//     Navigator.pushNamed(
//       context,
//       '/add-product',
//       arguments: {'product': _product},
//     );
//   }

//   Future<void> _deleteProduct() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Product'),
//         content: const Text('Are you sure you want to delete this product?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       final productProvider = Provider.of<ProductProvider>(
//         context,
//         listen: false,
//       );
//       final success = await productProvider.deleteProduct(_product!.id);

//       if (success) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Product deleted successfully')),
//         );
//       }
//     }
//   }

//   Color _getConditionColor(ProductCondition condition) {
//     switch (condition) {
//       case ProductCondition.brandNew:
//         return Colors.green;
//       case ProductCondition.likeNew:
//         return Colors.lightGreen;
//       case ProductCondition.good:
//         return Colors.orange;
//       case ProductCondition.fair:
//         return Colors.deepOrange;
//       case ProductCondition.poor:
//         return Colors.red;
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final diff = now.difference(date);

//     if (diff.inDays == 0) {
//       return 'Today';
//     } else if (diff.inDays == 1) {
//       return 'Yesterday';
//     } else if (diff.inDays < 7) {
//       return '${diff.inDays} days ago';
//     } else {
//       return DateFormat('MMM dd, yyyy').format(date);
//     }
//   }
// }

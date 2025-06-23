// lib/screens/profile/reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rating_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/rating_model.dart';

class ReviewsScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's reviews
  final String? userName;

  const ReviewsScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RatingModel> _sellerRatings = [];
  List<RatingModel> _buyerRatings = [];
  List<RatingModel> _givenRatings = [];
  bool _isLoading = true;
  String _targetUserId = '';
  String _targetUserName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUserData();
  }

  void _initializeUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _targetUserId = widget.userId ?? authProvider.userModel?.uid ?? '';
    _targetUserName = widget.userName ?? authProvider.userModel?.name ?? 'User';
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (_targetUserId.isEmpty) return;

    setState(() => _isLoading = true);

    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);

    try {
      // Load reviews received as seller
      final sellerRatings = await ratingProvider.getUserRatings(
        _targetUserId,
        isSellerRating: true,
      );

      // Load reviews received as buyer
      final buyerRatings = await ratingProvider.getUserRatings(
        _targetUserId,
        isSellerRating: false,
      );

      // Load reviews given by user (only show if viewing own profile)
      List<RatingModel> givenRatings = [];
      if (widget.userId == null) {
        givenRatings = await ratingProvider.getRatingsGivenByUser(_targetUserId);
      }

      setState(() {
        _sellerRatings = sellerRatings;
        _buyerRatings = buyerRatings;
        _givenRatings = givenRatings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reviews: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_targetUserName}\'s Reviews'),
        backgroundColor: const Color(0xFF078893),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'As Seller',
              icon: Badge(
                label: Text('${_sellerRatings.length}'),
                child: const Icon(Icons.storefront),
              ),
            ),
            Tab(
              text: 'As Buyer',
              icon: Badge(
                label: Text('${_buyerRatings.length}'),
                child: const Icon(Icons.shopping_bag),
              ),
            ),
            if (widget.userId == null)
              Tab(
                text: 'Given',
                icon: Badge(
                  label: Text('${_givenRatings.length}'),
                  child: const Icon(Icons.rate_review),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList(_sellerRatings, 'seller'),
          _buildReviewsList(_buyerRatings, 'buyer'),
          if (widget.userId == null)
            _buildReviewsList(_givenRatings, 'given'),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<RatingModel> ratings, String type) {
    if (ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'seller'
                  ? Icons.storefront_outlined
                  : type == 'buyer'
                  ? Icons.shopping_bag_outlined
                  : Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'seller'
                  ? 'No reviews as seller yet'
                  : type == 'buyer'
                  ? 'No reviews as buyer yet'
                  : 'No reviews given yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'seller'
                  ? 'Reviews from buyers will appear here'
                  : type == 'buyer'
                  ? 'Reviews from sellers will appear here'
                  : 'Reviews you\'ve given will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate average rating
    final averageRating = ratings.fold<double>(
      0.0,
          (sum, rating) => sum + rating.rating,
    ) / ratings.length;

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF078893).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF078893).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF078893),
                      ),
                    ),
                    _buildStarRating(averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '${ratings.length} review${ratings.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      _buildRatingBar(
                        i,
                        ratings.where((r) => r.rating == i).length,
                        ratings.length,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reviews List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildReviewCard(rating, type);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(RatingModel rating, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF078893),
                  child: Text(
                    (type == 'given' ? rating.toUserName : rating.fromUserName)
                        .isNotEmpty
                        ? (type == 'given' ? rating.toUserName : rating.fromUserName)[0]
                        .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'given' ? rating.toUserName : rating.fromUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(rating.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(rating.rating.toDouble()),
              ],
            ),
            if (rating.review != null && rating.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rating.review!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rating.isSellerRating
                        ? Colors.green[100]
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rating.isSellerRating ? 'Seller Review' : 'Buyer Review',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: rating.isSellerRating
                          ? Colors.green[700]
                          : Colors.blue[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  rating.ratingText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getRatingColor(rating.rating),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 16);
        }
      }),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/features_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../data/repositories/auction_repository.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/notification_repository.dart';

class RateUserScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? auctionId;

  const RateUserScreen({
    super.key,
    required this.userId,
    this.auctionId,
  });

  @override
  ConsumerState<RateUserScreen> createState() => _RateUserScreenState();
}

class _RateUserScreenState extends ConsumerState<RateUserScreen> with SingleTickerProviderStateMixin {
  int _rating = 0;
  // ...
  String? _resolvedUserId;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this, duration: const Duration(milliseconds: 600)
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    
    if (widget.userId == 'placeholder' && widget.auctionId != null) {
      _resolveUserId();
    } else {
        _resolvedUserId = widget.userId;
    }
  }

  Future<void> _resolveUserId() async {
      setState(() => _isLoadingUser = true);
      try {
          if (widget.auctionId == null) throw Exception('Auction ID required to resolve user');

          final auction = await ref.read(auctionRepositoryProvider).getAuction(widget.auctionId!);
          final currentUser = ref.read(currentUserProvider);
          
          if (currentUser == null) throw Exception('User not logged in');
          
          String? targetId;
          
          // If I am the winner, I rate the seller
          if (auction.winnerId == currentUser.id) {
            targetId = auction.sellerId;
          } 
          // If I am the seller, I rate the winner
          else if (auction.sellerId == currentUser.id) {
            targetId = auction.winnerId;
          }
          
          if (targetId == null) {
             throw Exception('You are neither the winner nor the seller of this auction');
          }
          
          if (mounted) {
            setState(() {
              _resolvedUserId = targetId;
              _isLoadingUser = false;
            });
          }
      } catch (e) {
          debugPrint('Error resolving user: $e');
          if (mounted) {
             setState(() => _isLoadingUser = false);
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Could not load user details: $e'), backgroundColor: AppColors.error),
             );
          }
      }
  }

  int _communicationRating = 0;
  int _accuracyRating = 0;
  int _speedRating = 0;
  
  final _reviewController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _wouldRecommend = true;
  bool _isSubmitting = false;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _feedbackTags = [
    'Fast Payment', 'Quick Shipping', 'Polite', 'Responsive', 
    'Item as Described', 'Friendly', 'Professional'
  ];



  @override
  void dispose() {
    _reviewController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an overall rating')),
      );
      return;
    }
    
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (_resolvedUserId == null) {
          throw Exception('User to rate is not identified');
      }

      // Append tags to review if selected
      String reviewText = _reviewController.text.trim();
      if (_selectedTags.isNotEmpty) {
        final tagsStr = _selectedTags.map((t) => '#${t.replaceAll(' ', '')}').join(' ');
        if (reviewText.isNotEmpty) {
          reviewText += '\n\n$tagsStr';
        } else {
          reviewText = tagsStr;
        }
      }

      await ref.read(featuresRepositoryProvider).rateUser(
        userId: _resolvedUserId!,
        auctionId: widget.auctionId,
        rating: _rating,
        communicationRating: _communicationRating > 0 ? _communicationRating : _rating,
        accuracyRating: _accuracyRating > 0 ? _accuracyRating : _rating,
        speedRating: _speedRating > 0 ? _speedRating : _rating,
        review: reviewText.isNotEmpty ? reviewText : null,
        wouldRecommend: _wouldRecommend,
      );

      // Update notification state locally so button disappears
      if (widget.auctionId != null) {
         ref.read(notificationsProvider.notifier).markAsRated(widget.auctionId!);
      }

      if (mounted) {
        context.pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for your feedback!'), 
            backgroundColor: AppColors.success
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error: $e';
        if (e.toString().contains('500') || e.toString().contains('duplicate')) {
          errorMessage = 'You have already rated this user for this auction.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarRating(String label, int value, Function(int) onChanged, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: isLarge ? AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold) : AppTypography.bodyMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: isLarge ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: List.generate(5, (index) {
            final int starValue = index + 1;
            final isSelected = starValue <= value;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
                  size: isLarge ? 48 : 28,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Rate Experience'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surfaceLight,
                      child: Icon(Icons.person, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How was it?',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your feedback helps the community',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Main Rating
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStarRating('Overall Rating', _rating, (v) => setState(() => _rating = v), isLarge: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Quick Tags
              Text('What went well?', style: AppTypography.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _feedbackTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                         selected ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      )
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Review Text
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share more details (optional)...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              // Recommendation Switch
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text('Recommend this user?', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _wouldRecommend,
                  onChanged: (val) => setState(() => _wouldRecommend = val),
                  activeColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),
              
              // Submit Button
              AppButton(
                label: 'Submit Feedback',
                isLoading: _isSubmitting,
                onPressed: _submitRating,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/features_repository.dart';
import '../../widgets/common/app_button.dart';

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

class _RateUserScreenState extends ConsumerState<RateUserScreen> {
  int _rating = 5;
  int _communicationRating = 5;
  int _accuracyRating = 5;
  int _speedRating = 5;
  final _reviewController = TextEditingController();
  bool _wouldRecommend = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(featuresRepositoryProvider).rateUser(
        userId: widget.userId,
        auctionId: widget.auctionId,
        rating: _rating,
        communicationRating: _communicationRating,
        accuracyRating: _accuracyRating,
        speedRating: _speedRating,
        review: _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
        wouldRecommend: _wouldRecommend,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!'), backgroundColor: AppColors.success),
        );
        context.pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarRating(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < value ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 32,
              ),
              onPressed: () => onChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate User'),
        backgroundColor: AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How was your experience?', style: AppTypography.headlineSmall),
            const SizedBox(height: 24),
            
            _buildStarRating('Overall Rating', _rating, (val) => setState(() => _rating = val)),
            const SizedBox(height: 16),
            _buildStarRating('Communication', _communicationRating, (val) => setState(() => _communicationRating = val)),
            const SizedBox(height: 16),
            _buildStarRating('Item Accuracy', _accuracyRating, (val) => setState(() => _accuracyRating = val)),
            const SizedBox(height: 16),
            _buildStarRating('Speed', _speedRating, (val) => setState(() => _speedRating = val)),
            
            const SizedBox(height: 24),
            Text('Review (Optional)', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share details about your experience...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('Would you recommend this user?', style: AppTypography.titleSmall),
              value: _wouldRecommend,
              onChanged: (val) => setState(() => _wouldRecommend = val),
              activeColor: AppColors.success,
            ),
            
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit Rating',
              isLoading: _isSubmitting,
              onPressed: _submitRating,
            ),
          ],
        ),
      ),
    );
  }
}

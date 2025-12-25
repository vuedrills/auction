import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/websocket_service.dart';
import '../../data/providers/websocket_provider.dart';
import '../../app/theme.dart';

/// WebSocket connection status indicator widget
class WsConnectionIndicator extends ConsumerWidget {
  final bool showLabel;
  final double size;
  
  const WsConnectionIndicator({
    super.key,
    this.showLabel = false,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(wsConnectionStateProvider);
    
    return connectionState.when(
      data: (state) => _buildIndicator(state),
      loading: () => _buildIndicator(WsConnectionState.connecting),
      error: (_, __) => _buildIndicator(WsConnectionState.error),
    );
  }
  
  Widget _buildIndicator(WsConnectionState state) {
    final Color color;
    final String label;
    
    switch (state) {
      case WsConnectionState.connected:
        color = AppColors.success;
        label = 'Live';
        break;
      case WsConnectionState.connecting:
        color = AppColors.warning;
        label = 'Connecting...';
        break;
      case WsConnectionState.error:
        color = AppColors.error;
        label = 'Offline';
        break;
      case WsConnectionState.disconnected:
        color = AppColors.textSecondaryLight;
        label = 'Disconnected';
        break;
    }
    
    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(color, state == WsConnectionState.connecting),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      );
    }
    
    return _buildDot(color, state == WsConnectionState.connecting);
  }
  
  Widget _buildDot(Color color, bool pulsing) {
    if (pulsing) {
      return _PulsingDot(color: color, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  
  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Real-time bid update toast widget
class BidUpdateToast extends StatelessWidget {
  final String bidderName;
  final double amount;
  final VoidCallback? onBidAgain;
  
  const BidUpdateToast({
    super.key,
    required this.bidderName,
    required this.amount,
    this.onBidAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.gavel, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Bid!',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                ),
                Text(
                  '$bidderName bid \$${amount.toStringAsFixed(2)}',
                  style: AppTypography.titleSmall,
                ),
              ],
            ),
          ),
          if (onBidAgain != null)
            TextButton(
              onPressed: onBidAgain,
              child: Text(
                'Bid Now',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Outbid notification banner
class OutbidBanner extends StatelessWidget {
  final String auctionTitle;
  final double newAmount;
  final VoidCallback onViewAuction;
  final VoidCallback onDismiss;
  
  const OutbidBanner({
    super.key,
    required this.auctionTitle,
    required this.newAmount,
    required this.onViewAuction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'You\'ve been outbid!',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            auctionTitle,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'New highest bid: \$${newAmount.toStringAsFixed(2)}',
            style: AppTypography.labelMedium.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewAuction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Bid Again', style: AppTypography.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

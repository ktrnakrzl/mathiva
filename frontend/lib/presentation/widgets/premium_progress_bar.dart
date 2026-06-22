import 'package:flutter/material.dart';
import 'package:mathiva/core/constants/app_colors.dart';

/// Premium minimal progress bar with only accent color used.
class PremiumProgressBar extends StatelessWidget {
  final double progress;
  final String? label;
  final bool showPercentage;

  const PremiumProgressBar({
    Key? key,
    required this.progress,
    this.label,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label and percentage
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        
        // Thin progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

/// Premium circular progress indicator with accent color.
class PremiumCircularProgress extends StatelessWidget {
  final double progress;
  final String? label;
  final double size;

  const PremiumCircularProgress({
    Key? key,
    required this.progress,
    this.label,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            CircularProgressIndicator(
              value: 1,
              minWidth: size,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.borderColor),
            ),
            // Progress circle
            CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minWidth: size,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            // Center text
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Premium completion badge with accent color.
class CompletionBadge extends StatelessWidget {
  final bool isComplete;
  final String label;

  const CompletionBadge({
    Key? key,
    required this.isComplete,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.accent.withValues(alpha: 0.1) : AppColors.borderColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? AppColors.accent : AppColors.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isComplete) ...[
            const Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isComplete ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

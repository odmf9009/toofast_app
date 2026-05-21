import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class FeatureTitle extends StatelessWidget {
  final String title;
  final bool isLocked;

  const FeatureTitle({
    super.key,
    required this.title,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 12)),
        if (isLocked) ...[
          const SizedBox(width: 6),
          const Icon(Icons.lock, color: Colors.yellow, size: 12),
        ],
      ],
    );
  }
}

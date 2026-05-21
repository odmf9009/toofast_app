import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class OfertaPlaceholder extends StatelessWidget {
  final double width;
  final String height; // Wait, height was double in the code? Let's check main.dart

  const OfertaPlaceholder({super.key, this.width = 85, this.height = "85"});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.tryParse(height) ?? 85,
      color: AppColors.background,
      child: const Icon(Icons.image_outlined, color: AppColors.border, size: 30),
    );
  }
}

// Global helper function for easier transition
Widget buildPlaceholder({double width = 85, double height = 85}) {
  return Container(
    width: width,
    height: height,
    color: AppColors.background,
    child: const Icon(Icons.image_outlined, color: AppColors.border, size: 30),
  );
}

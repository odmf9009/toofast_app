import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 12),
          Text(value, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, 
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

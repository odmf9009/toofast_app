import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class DataRowItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isNeon;

  const DataRowItem({
    super.key,
    required this.label,
    required this.value,
    this.isNeon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
        Text(value, 
          style: TextStyle(
            color: isNeon ? AppColors.primary : Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 14
          )
        ),
      ],
    );
  }
}

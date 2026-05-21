import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String prefix;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.prefix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)
      ),
      child: Row(
        children: [
          Text('$prefix ', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey, 
                fontSize: 13, 
                fontWeight: FontWeight.bold
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

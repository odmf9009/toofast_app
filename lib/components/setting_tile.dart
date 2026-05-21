import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSwitch;
  final bool? value;
  final Function(bool)? onChanged;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSwitch = false,
    this.value,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: AppColors.border)
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), 
          child: Icon(icon, color: AppColors.textGrey, size: 20)
        ),
        title: Text(title, 
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, 
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        trailing: isSwitch 
          ? Switch(value: value ?? true, onChanged: onChanged, activeColor: AppColors.primary) 
          : const Icon(Icons.arrow_forward_ios, color: AppColors.border, size: 14),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4), 
      child: Align(
        alignment: Alignment.centerLeft, 
        child: Text(title.toUpperCase(), 
          style: const TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold, 
            color: AppColors.textDarkGrey, 
            letterSpacing: 1.2
          )
        )
      )
    );
  }
}

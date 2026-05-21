import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../screens/main_navigation_screen.dart';

class AppUtils {
  static String formatearTiempo(int segundosTotales) {
    int minutos = segundosTotales ~/ 60;
    int segundos = segundosTotales % 60;
    String minStr = minutos.toString().padLeft(2, '0');
    String segStr = segundos.toString().padLeft(2, '0');
    return '$minStr:$segStr min';
  }

  static void mostrarPremiumDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💎 Función Premium', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
              navState?.cambiarAPestana(4); // Ir a Perfil
            },
            child: const Text('Mejorar ahora', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

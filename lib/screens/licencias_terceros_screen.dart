import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class LicenciasTercerosScreen extends StatelessWidget {
  const LicenciasTercerosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licencias de Terceros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Licencia de Terceros — TooFast',
              style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Última actualización: 22 de mayo de 2026',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'TooFast puede utilizar tecnologías, bibliotecas y servicios de terceros para operar correctamente.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection('Tecnologías utilizadas', 
              'La aplicación puede utilizar:\n• Flutter\n• Firebase\n• Google Play Services\n• Android SDK\n• Librerías Open Source\n• Servicios de notificaciones y análisis'),
            _buildSection('Licencias Open Source', 
              'Algunas bibliotecas utilizadas están sujetas a licencias de código abierto, incluyendo:\n• MIT License\n• Apache License 2.0\n• BSD License\n\nCada componente mantiene sus propios derechos y condiciones de uso.'),
            _buildSection('Marcas registradas', 
              'Todos los nombres comerciales y marcas mencionadas pertenecen a sus respectivos propietarios.\n\nRevolico es propiedad de sus respectivos titulares y TooFast no reclama ninguna relación oficial con dicha plataforma.'),
            _buildSection('Exención de responsabilidad', 
              'Los servicios y componentes de terceros son proporcionados “tal cual” según sus respectivas licencias.\n\nTooFast no garantiza el funcionamiento permanente de servicios externos integrados en la aplicación.'),
            _buildSection('Contacto', 
              'support@gettoofast.com'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

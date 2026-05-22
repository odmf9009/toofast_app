import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad — TooFast',
              style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Última actualización: 22 de mayo de 2026',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Introducción', 
              'Bienvenido a TooFast.\n\nTooFast es una aplicación diseñada para ayudar a los usuarios a rastrear anuncios publicados en plataformas de clasificados como Revolico y recibir alertas rápidas sobre nuevas publicaciones según sus preferencias.\n\nAl utilizar la aplicación, aceptas esta Política de Privacidad.'),
            _buildSection('2. Información que recopilamos', 
              'Información proporcionada por el usuario:\n• Correo electrónico\n• Nombre de usuario\n• Categorías favoritas\n• Palabras clave de búsqueda\n• Configuración de alertas y filtros\n\nInformación recopilada automáticamente:\n• Tipo de dispositivo\n• Dirección IP\n• Sistema operativo\n• Datos de uso de la aplicación\n• Errores técnicos y estadísticas'),
            _buildSection('3. Uso de la información', 
              'La información recopilada se utiliza para:\n• Enviar alertas rápidas sobre anuncios nuevos\n• Mejorar el funcionamiento de la aplicación\n• Personalizar búsquedas y filtros\n• Analizar rendimiento y estabilidad\n• Prevenir abuso o uso indebido'),
            _buildSection('4. Compartición de información', 
              'TooFast no vende información personal de los usuarios.\n\nPodemos compartir información únicamente con proveedores tecnológicos necesarios para operar la aplicación, como servicios de hosting, análisis o notificaciones.'),
            _buildSection('5. Relación con Revolico', 
              'TooFast no está afiliado, asociado ni respaldado oficialmente por Revolico.\n\nLa aplicación únicamente ayuda a los usuarios a monitorear publicaciones públicas disponibles en plataformas externas.\n\nTodos los derechos sobre contenido, marcas y publicaciones pertenecen a sus respectivos propietarios.'),
            _buildSection('6. Notificaciones', 
              'Si el usuario activa las notificaciones, TooFast podrá enviar:\n• Alertas de nuevos anuncios\n• Actualizaciones relevantes\n• Notificaciones relacionadas con búsquedas guardadas\n\nEl usuario puede desactivar las notificaciones en cualquier momento desde la configuración del dispositivo.'),
            _buildSection('7. Seguridad', 
              'Implementamos medidas razonables para proteger la información de los usuarios.\n\nSin embargo, ningún sistema es completamente seguro y no podemos garantizar seguridad absoluta.'),
            _buildSection('8. Menores de edad', 
              'TooFast no está dirigido a menores de 13 años.'),
            _buildSection('9. Cambios en esta política', 
              'Podemos actualizar esta Política de Privacidad en cualquier momento.\n\nLos cambios entrarán en vigor una vez publicados en la aplicación.'),
            _buildSection('10. Contacto', 
              'Correo de soporte: support@gettoofast.com'),
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

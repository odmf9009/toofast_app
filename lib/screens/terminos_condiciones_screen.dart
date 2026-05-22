import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones — TooFast',
              style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Última actualización: 22 de mayo de 2026',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Aceptación de términos', 
              'Al utilizar TooFast, aceptas estos Términos y Condiciones.\n\nSi no estás de acuerdo, debes dejar de utilizar la aplicación.'),
            _buildSection('2. Descripción del servicio', 
              'TooFast permite a los usuarios:\n• Monitorear anuncios publicados en plataformas externas\n• Recibir alertas rápidas\n• Configurar filtros y categorías\n• Ver publicaciones detectadas automáticamente'),
            _buildSection('3. Independencia de terceros', 
              'TooFast no pertenece ni representa oficialmente a Revolico ni a ninguna otra plataforma externa.\n\nLa aplicación únicamente organiza y muestra información públicamente disponible.'),
            _buildSection('4. Uso permitido', 
              'El usuario acepta:\n• Utilizar la aplicación legalmente\n• No intentar afectar el funcionamiento del sistema\n• No utilizar la plataforma para actividades ilegales\n• No copiar ni redistribuir el contenido de la aplicación sin autorización'),
            _buildSection('5. Disponibilidad del servicio', 
              'No garantizamos:\n• Funcionamiento continuo\n• Ausencia de interrupciones\n• Exactitud total de los anuncios mostrados\n• Disponibilidad permanente de publicaciones externas\n\nLos anuncios pueden ser eliminados o modificados por sus autores originales.'),
            _buildSection('6. Contenido externo', 
              'TooFast muestra información obtenida de plataformas externas.\n\nNo somos responsables por:\n• Exactitud de los anuncios\n• Estafas o fraudes\n• Cambios de precio\n• Disponibilidad de productos\n• Interacciones entre usuarios y vendedores externos\n\nEl usuario es responsable de verificar cualquier transacción realizada fuera de la aplicación.'),
            _buildSection('7. Propiedad intelectual', 
              'Todo el diseño, interfaz, código y elementos visuales de TooFast pertenecen a sus respectivos propietarios.\n\nNo está permitido copiar, modificar o redistribuir partes de la aplicación sin autorización.'),
            _buildSection('8. Limitación de responsabilidad', 
              'TooFast no será responsable por:\n• Pérdidas económicas\n• Problemas derivados de compras externas\n• Publicaciones falsas o fraudulentas\n• Interrupciones del servicio\n• Daños indirectos o incidentales\n\nEl uso de la aplicación es bajo responsabilidad del usuario.'),
            _buildSection('9. Suspensión de cuentas', 
              'Podemos suspender cuentas que:\n• Violenten estos términos\n• Realicen abuso del sistema\n• Intenten comprometer la seguridad de la plataforma'),
            _buildSection('10. Cambios en los términos', 
              'Estos términos pueden actualizarse en cualquier momento.\n\nEl uso continuo de la aplicación implica aceptación de los cambios.'),
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

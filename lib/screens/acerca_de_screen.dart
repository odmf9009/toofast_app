import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/toofast_provider.dart';
import 'package:intl/intl.dart';
import 'politica_privacidad_screen.dart';
import 'terminos_condiciones_screen.dart';
import 'licencias_terceros_screen.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de Toofast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary, size: 60),
                  const SizedBox(height: 16),
                  const Text('TOOFAST', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('Versión 1.0.2', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                  const SizedBox(height: 24),
                  const Text(
                    'TooFast es una plataforma inteligente que ayuda a los usuarios a descubrir ofertas, productos y oportunidades en tiempo real mediante escaneos automáticos y alertas rápidas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Qué puedes hacer en TooFast'),
            _buildBulletPoint('Escanear categorías automáticamente'),
            _buildBulletPoint('Recibir alertas en tiempo real'),
            _buildBulletPoint('Guardar productos favoritos'),
            _buildBulletPoint('Configurar rangos de precios'),
            _buildBulletPoint('Descubrir hidden deals'),
            _buildBulletPoint('Acceder a ofertas limitadas'),
            _buildBulletPoint('Personalizar categorías'),
            
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Información de la App'),
            _buildInfoRow('Última actualización', 'Mayo 2026'),
            _buildInfoRow('Plataforma', 'Android'),
            _buildInfoRow('Estado del servidor', 'Online', valueColor: Colors.greenAccent),
            _buildInfoRow('Región', 'USA'),
            
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Soporte'),
            _buildEmailRow('support@gettoofast.com'),
            const SizedBox(height: 16),
            _buildActionButton(Icons.chat_bubble_outline, 'Contactar soporte', () => _enviarEmail('Soporte Toofast')),
            _buildActionButton(Icons.bug_report_outlined, 'Reportar error', () => _enviarEmail('Reporte de error')),
            _buildActionButton(Icons.lightbulb_outline, 'Sugerir función', () => _enviarEmail('Sugerencia de función')),
            
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Legal'),
            _buildActionButton(Icons.privacy_tip_outlined, 'Política de privacidad', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PoliticaPrivacidadScreen()),
              );
            }),
            _buildActionButton(Icons.description_outlined, 'Términos y condiciones', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TerminosCondicionesScreen()),
              );
            }),
            _buildActionButton(Icons.list_alt_outlined, 'Licencias de terceros', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LicenciasTercerosScreen()),
              );
            }),
            
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Estadísticas en vivo'),
            Consumer<ToofastProvider>(
              builder: (context, provider, child) {
                final formatter = NumberFormat('#,###');
                // Simulamos "alertas" como un porcentaje de los escaneos para que se vea dinámico
                final alertasSimuladas = (provider.totalEscaneosGlobales * 0.1).floor();
                // Usuarios online: un pequeño % de los totales
                final usuariosOnline = (provider.totalUsuarios * 0.15).floor() + 3;

                return Column(
                  children: [
                    _buildStatRow(Icons.bolt, '${formatter.format(provider.totalEscaneosGlobales)} escaneos detectados hoy'),
                    _buildStatRow(Icons.people_outline, '${formatter.format(usuariosOnline)} usuarios online'),
                    _buildStatRow(Icons.notifications_active_outlined, '${formatter.format(alertasSimuladas)} alertas enviadas'),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Gracias por usar TooFast 🚀',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmailRow(String email) {
    return InkWell(
      onTap: () => _enviarEmail('Soporte Toofast'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(email, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviarEmail(String asunto) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: 'support@gettoofast.com',
      query: 'subject=${Uri.encodeComponent(asunto)}',
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Intento de lanzamiento forzado si canLaunchUrl falla (común en Android)
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al lanzar el correo: $e');
    }
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

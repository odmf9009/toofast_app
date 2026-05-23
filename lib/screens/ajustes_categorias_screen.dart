import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../utils/app_utils.dart';
import 'faq_screen.dart';

class AjustesCategoriasScreen extends StatelessWidget {
  const AjustesCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToofastProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interfaz y Menú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalizar Menú Lateral',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige qué categorías quieres que aparezcan en tu panel de filtros lateral. Mantén solo lo que necesitas.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false, // ✨ Recogido por defecto
                  leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                  title: const Text('Categorías', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  children: [
                    CheckboxListTile(
                      title: const Text('Seleccionar Todo', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      value: provider.categoriasVisibles.length == provider.listaCategorias.length,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      onChanged: (bool? value) {
                        if (!provider.esPremium) {
                          AppUtils.mostrarPremiumDialog(context, "La personalización masiva es una función exclusiva para usuarios Premium.");
                          return;
                        }
                        provider.toggleTodasCategorias(value == true);
                      },
                    ),
                    const Divider(color: AppColors.border, indent: 16, endIndent: 16),
                    ...provider.listaCategorias.map((slug) {
                      final bool estaVisible = provider.categoriasVisibles.contains(slug);
                      final String nombre = provider.nombresCategorias[slug] ?? slug;
                      
                      return CheckboxListTile(
                        title: Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        value: estaVisible,
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        subtitle: Text(estaVisible ? 'Visible en el menú' : 'Oculta', 
                          style: TextStyle(color: estaVisible ? AppColors.primary.withOpacity(0.7) : AppColors.textGrey, fontSize: 12)),
                        onChanged: (bool? value) {
                          if (!provider.esPremium) {
                            AppUtils.mostrarPremiumDialog(context, "La personalización del menú lateral es una función exclusiva para usuarios Premium.");
                            return;
                          }
                          provider.toggleVisibilidadCategoria(slug);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debes mantener al menos una categoría activa.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 🌟 SECCIÓN COMUNIDAD Y SOPORTE
            const Text(
              'Comunidad y Soporte',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Invitar amigos',
                    subtitle: 'Comparte Toofast con tus contactos',
                    onTap: () {
                      AppUtils.mostrarSnackBar(context, "Función de invitación próximamente disponible.");
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 55),
                  _buildSettingTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'FAQ',
                    subtitle: 'Preguntas frecuentes y ayuda',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 55),
                  _buildSettingTile(
                    context,
                    icon: Icons.star_outline_rounded,
                    title: 'Calificar App',
                    subtitle: 'Danos tu opinión en la tienda',
                    onTap: () {
                      AppUtils.mostrarSnackBar(context, "¡Gracias! Pronto podrás calificarnos en la Play Store.");
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 55),
                  _buildSettingTile(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'Soporte Técnico',
                    subtitle: '¿Necesitas ayuda? Contáctanos',
                    onTap: () {
                      _enviarEmail(context, 'Soporte Técnico Toofast');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 12),
      onTap: onTap,
    );
  }

  Future<void> _enviarEmail(BuildContext context, String asunto) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: 'support@gettoofast.com',
      query: 'subject=${Uri.encodeComponent(asunto)}',
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al lanzar el correo: $e');
    }
  }
}

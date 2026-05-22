import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../components/stat_card.dart';
import '../components/setting_tile.dart';
import '../components/section_title.dart';
import '../utils/app_utils.dart';
import 'datos_usuario_screen.dart';
import 'panel_admin_usuarios_screen.dart';
import 'acerca_de_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    return Scaffold(
      drawer: AppDrawer(provider: toofastProvider),
      appBar: AppBar(
        title: const Center(child: Text('Mi Perfil', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: const [Icon(Icons.edit_outlined, color: AppColors.textGrey), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
            Center(
              child: Column(
                children: [
                  if (toofastProvider.estaLogueado) ...[
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => toofastProvider.cambiarFotoPerfil(),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.surface,
                            backgroundImage: (toofastProvider.fotoPerfilUrl != null && !toofastProvider.estaCargandoFoto)
                                ? (toofastProvider.fotoPerfilUrl!.startsWith('data:image') 
                                    ? MemoryImage(base64Decode(toofastProvider.fotoPerfilUrl!.split(',')[1])) as ImageProvider
                                    : NetworkImage(toofastProvider.fotoPerfilUrl!))
                                : null,
                            child: toofastProvider.estaCargandoFoto 
                                ? const CircularProgressIndicator(color: AppColors.secondary)
                                : (toofastProvider.fotoPerfilUrl == null 
                                    ? Text(toofastProvider.usuario!.displayName?[0].toUpperCase() ?? '?', 
                                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white))
                                    : null),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => toofastProvider.cambiarFotoPerfil(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        if (toofastProvider.esPremium)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                              child: const Icon(Icons.bolt, size: 16, color: AppColors.background),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(toofastProvider.usuario!.displayName ?? 'Usuario', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(toofastProvider.usuario!.email, 
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  ] else ...[
                    const CircleAvatar(radius: 50, backgroundColor: AppColors.surface, 
                      child: Icon(Icons.person_outline, size: 50, color: Colors.white24)),
                    const SizedBox(height: 20),
                    const Text('Inicia sesión para sincronizar', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try { await toofastProvider.iniciarSesionGoogle(); } catch (e) {
                          if (context.mounted) { 
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al iniciar sesión: $e'))
                            ); 
                          }
                        }
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Entrar con Google', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface, 
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), 
                          side: const BorderSide(color: AppColors.border)
                        )
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Favoritos', value: '${toofastProvider.ofertasGuardadas.length}', icon: Icons.favorite_border)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Vistos', value: '${toofastProvider.ofertasEncontradas.length}', icon: Icons.remove_red_eye_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => AppUtils.mostrarBeneficiosPremium(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: toofastProvider.esPremium 
                      ? [AppColors.premiumGreenStart, AppColors.premiumGreenEnd]
                      : [AppColors.orangeStart, AppColors.orangeEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (toofastProvider.esPremium ? AppColors.secondary : AppColors.primary).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        toofastProvider.esPremium ? Icons.check_circle_outline : Icons.workspace_premium, 
                        color: Colors.white, 
                        size: 30
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toofastProvider.esPremium ? 'Membresía Premium Activa' : 'Membresía Premium',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            toofastProvider.esPremium 
                                ? 'Tiempo restante: ${toofastProvider.tiempoRestantePremium}'
                                : 'Desbloquea escaneos ilimitados y filtros avanzados',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const SectionTitle(title: 'Preferencias de App'),
            SettingTile(
              icon: Icons.notifications_none, 
              title: 'Notificaciones de radar', 
              subtitle: toofastProvider.notificacionesHabilitadas ? 'Habilitadas' : 'Deshabilitadas', 
              isSwitch: true, 
              value: toofastProvider.notificacionesHabilitadas, 
              onChanged: (v) => toofastProvider.setNotificaciones(v)
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Cuenta y Seguridad'),
            SettingTile(
              icon: Icons.info_outline, 
              title: 'Acerca de Toofast', 
              subtitle: 'Versión 1.0.2',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AcercaDeScreen()));
              },
            ),
            
            if (toofastProvider.esAdmin) ...[
              const SizedBox(height: 24),
              const SectionTitle(title: 'Administración'),
              SettingTile(
                icon: Icons.admin_panel_settings_outlined, 
                title: 'Panel de Control', 
                subtitle: 'Usuarios y actividad en vivo', 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PanelAdminUsuariosScreen()));
                }
              ),
            ],

            const SizedBox(height: 40),
            if (toofastProvider.estaLogueado)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => toofastProvider.cerrarSesion(),
                  icon: const Icon(Icons.logout, color: AppColors.errorRed, size: 20),
                  label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14), 
                    backgroundColor: AppColors.errorRed.withOpacity(0.1), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';

class DatosUsuarioScreen extends StatelessWidget {
  const DatosUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToofastProvider>(context);
    final user = provider.usuario;

    return Scaffold(
      drawer: AppDrawer(provider: provider),
      appBar: AppBar(
        title: const Text('Mis Datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: user == null 
          ? const Center(child: Text('Inicia sesión para ver tus datos'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataItem('ID de Usuario', user.id),
                  _buildDataItem('Nombre Completo', user.displayName ?? 'No disponible'),
                  _buildDataItem('Correo Electrónico', user.email),
                  _buildDataItem('Estado de Membresía', provider.esPremium ? 'Premium 💎' : 'Gratis (Freemium)'),
                  const Spacer(),
                  const Text(
                    'Toofast respeta tu privacidad. Estos datos se utilizan para sincronizar tus favoritos y filtros entre dispositivos.',
                    style: TextStyle(color: Color(0xFF4C6A92), fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final ToofastProvider provider;

  const AppDrawer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Filtro de Categorías',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Selecciona las categorías que deseas ver en el Home para escanear.',
                style: TextStyle(fontSize: 13, color: AppColors.textLightGrey),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: const Text(
                        'Categorías',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: Colors.white70,
                      childrenPadding: const EdgeInsets.only(left: 12),
                      initiallyExpanded: false,
                      children: [
                        CheckboxListTile(
                          title: const Text('✨  Seleccionar Todo (All)', 
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          value: provider.categoriasVisibles.length == provider.listaCategorias.length,
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            provider.toggleTodasCategorias(value ?? true);
                          },
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                        const Divider(color: AppColors.border, indent: 16, endIndent: 16),
                        
                        ...provider.listaCategorias.map((slug) {
                          final bool estaVisible = provider.categoriasVisibles.contains(slug);
                          final Map<String, String> nombresEsteticos = {
                            'vehiculos': '🚗  Vehículos y Carros',
                            'inmobiliaria': '🏠  Casas y Alquileres',
                            'tecnologia': '💻  Tecnología y PC',
                            'electrodomesticos': '📺  Electrodomésticos',
                            'ropa-y-accesorios': '👟  Ropa y Accesorios',
                            'familia': '🍼  Artículos para Familia',
                            'general': '📦  Compra-Venta General',
                            'hogar': '🛋️  Muebles y Hogar',
                          };

                          return CheckboxListTile(
                            title: Text(nombresEsteticos[slug] ?? slug, 
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            value: estaVisible,
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            onChanged: (bool? value) {
                              provider.toggleVisibilidadCategoria(slug);
                            },
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

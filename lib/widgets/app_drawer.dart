import 'package:flutter/material.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../utils/app_utils.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: const Text(
                        'Categorías',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: Colors.white70,
                      children: provider.categoriasVisibles.map((catSlug) {
                        final subcats = provider.subcategorias[catSlug] ?? [];
                        final Map<String, String> iconos = {
                          'vehiculos': '🚗',
                          'inmobiliaria': '🏠',
                          'tecnologia': '💻',
                          'electrodomesticos': '📺',
                          'ropa-y-accesorios': '👟',
                          'servicios': '🛠️',
                          'empleos': '💼',
                          'hogar': '🛋️',
                        };

                        final String nombreBonito = provider.nombresCategorias[catSlug] ?? catSlug;
                        final bool isSelectedMain = provider.categoria == catSlug && provider.subcategoria.isEmpty;

                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Text(iconos[catSlug] ?? '📁', style: const TextStyle(fontSize: 20)),
                            title: Text(
                              nombreBonito,
                              style: TextStyle(
                                color: isSelectedMain ? AppColors.primary : Colors.white,
                                fontWeight: isSelectedMain ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14
                              ),
                            ),
                            iconColor: AppColors.primary,
                            collapsedIconColor: Colors.white60,
                            children: [
                              ListTile(
                                title: Text('Ver todo en $nombreBonito', 
                                  style: TextStyle(color: isSelectedMain ? AppColors.primary : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                onTap: () {
                                  provider.cambiarCategoria(catSlug);
                                  Navigator.pop(context);
                                },
                                trailing: isSelectedMain ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                              ),
                              ...subcats.map((sub) {
                                final bool isSelectedSub = provider.subcategoria == sub['slug'];
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(left: 48, right: 16),
                                  title: Text(sub['name'] ?? '', 
                                    style: TextStyle(
                                      color: isSelectedSub ? AppColors.primary : Colors.white60, 
                                      fontSize: 13
                                    )
                                  ),
                                  onTap: () {
                                    provider.cambiarCategoria(catSlug);
                                    provider.cambiarSubcategoria(sub['slug']!);
                                    Navigator.pop(context);
                                  },
                                  trailing: isSelectedSub ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
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

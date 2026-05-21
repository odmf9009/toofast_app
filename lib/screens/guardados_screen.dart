import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/oferta_card.dart';

class GuardadosScreen extends StatelessWidget {
  const GuardadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);
    final favoritos = toofastProvider.ofertasGuardadas;

    return Scaffold(
      drawer: AppDrawer(provider: toofastProvider),
      appBar: AppBar(
        title: const Center(child: Text('Anuncios guardados', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: [
          if (favoritos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.errorRed),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Eliminar todo', style: TextStyle(color: Colors.white)),
                    content: const Text('¿Estás seguro de que quieres borrar todos tus favoritos?', 
                      style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          toofastProvider.limpiarTodosFavoritos();
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar', style: TextStyle(color: AppColors.errorRed)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: favoritos.isEmpty
            ? const Center(
                child: Text('No tienes anuncios guardados.\nToca el corazón en las ofertas cazadas para retenerlas.', 
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14))
              )
            : ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: favoritos.length,
          itemBuilder: (context, index) {
            final item = favoritos[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OfertaCard(
                item: item,
                guardado: true,
                showDeleteIcon: true,
                onFavoriteTap: () => toofastProvider.toggleFavorito(item),
              ),
            );
          },
        ),
      ),
    );
  }
}

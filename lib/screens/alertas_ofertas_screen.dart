import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/oferta_card.dart';
import '../utils/app_utils.dart';
import 'main_navigation_screen.dart';

class AlertasOfertasScreen extends StatelessWidget {
  const AlertasOfertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);
    final ofertas = toofastProvider.ofertasEncontradas;

    return Scaffold(
      drawer: AppDrawer(provider: toofastProvider),
      appBar: AppBar(
        title: const Center(child: Text('Oportunidades encontradas', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1)
            ),
            child: Center(
              child: Text('${ofertas.length} HITS', 
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: !toofastProvider.isEscaneando
            ? const Center(
                child: Text('El radar está apagado.\nActívalo para empezar a cazar ofertas.', 
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14))
              )
            : ofertas.isEmpty
            ? Center(
                child: Text(
                  toofastProvider.palabraClave.isEmpty
                      ? 'Escaneando Revolico...\nNo hay ofertas en este rango todavía.'
                      : 'Escaneando Revolico...\nNo hay anuncios que coincidan con "${toofastProvider.palabraClave}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
              )
            : ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: ofertas.length,
          itemBuilder: (context, index) {
            final item = ofertas[index];
            final bool guardado = toofastProvider.esFavorito(item['id']!);
            final bool isLocked = !toofastProvider.esPremium && index >= 5;

            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: isLocked ? 5 : 0, sigmaY: isLocked ? 5 : 0),
                    child: OfertaCard(
                      item: item,
                      guardado: guardado,
                      isLocked: isLocked,
                      onFavoriteTap: () {
                        if (!guardado && !toofastProvider.esPremium && toofastProvider.ofertasGuardadas.isNotEmpty) {
                          AppUtils.mostrarPremiumDialog(context, 
                            "Los usuarios FREE solo pueden guardar 1 favorito. ¡Actualiza para favoritos ilimitados!");
                          return;
                        }
                        toofastProvider.toggleFavorito(item);
                      },
                    ),
                  ),
                ),

                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.yellow, size: 24),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () {
                                final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                                navState?.cambiarAPestana(4);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Desbloquear con Premium', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

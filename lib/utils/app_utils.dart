import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_colors.dart';
import '../screens/main_navigation_screen.dart';
import '../providers/toofast_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/stripe_service.dart';

class AppUtils {
  static String formatearTiempo(int segundosTotales) {
    int minutos = segundosTotales ~/ 60;
    int segundos = segundosTotales % 60;
    String minStr = minutos.toString().padLeft(2, '0');
    String segStr = segundos.toString().padLeft(2, '0');
    return '$minStr:$segStr min';
  }

  static void mostrarPremiumDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💎 Función Premium', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(dialogContext); // Cierra el diálogo
              final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
              if (navState != null) {
                navState.cambiarAPestana(4); // Salta a Perfil
                
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (navState.mounted) {
                    mostrarBeneficiosPremium(navState.context);
                  }
                });
              }
            },
            child: const Text('Mejorar ahora', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void mostrarBeneficiosPremium(BuildContext context) {
    final provider = Provider.of<ToofastProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        padding: EdgeInsets.only(
          left: 32, 
          right: 32, 
          top: 32, 
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 32
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const Text('Beneficios Premium 💎', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Lleva tu búsqueda de ofertas al siguiente nivel', style: TextStyle(color: AppColors.textLightGrey, fontSize: 14)),
              const SizedBox(height: 32),
              _buildBenefitItem(Icons.bolt, 'Escaneos en tiempo real', 'Sin límites de tiempo entre búsquedas.'),
              _buildBenefitItem(Icons.search, 'Filtros avanzados', 'Búsqueda por palabras clave y rango de precios.'),
              _buildBenefitItem(Icons.notifications_active, 'Notificaciones instantáneas', 'Entérate de las ofertas en el momento exacto.'),
              _buildBenefitItem(Icons.visibility, 'Resultados desbloqueados', 'Accede a los 20 resultados de cada escaneo.'),
              _buildBenefitItem(Icons.category_outlined, 'Filtro por categorías', 'Personaliza tu menú y oculta lo que no te interesa.'),
              _buildBenefitItem(Icons.favorite, 'Favoritos ilimitados', 'Guarda todas las ofertas que quieras.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!provider.estaLogueado) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, inicia sesión para adquirir la membresía.'), backgroundColor: AppColors.errorRed));
                      return;
                    }

                    if (provider.esPremium) {
                      if (provider.planActual == '6 Meses + 20 Días') {
                        Navigator.pop(sheetContext);
                        mostrarPremiumDialog(context, "Usted ha adquirido la membresía máxima. ¡Gracias por tu apoyo!");
                        return;
                      }
                    }

                    Navigator.pop(sheetContext);
                    _mostrarPlanesMembresia(context, provider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    elevation: 8, 
                    shadowColor: AppColors.primary.withOpacity(0.4)
                  ),
                  child: Text(provider.esPremium ? 'Mejorar membresía' : 'Obtener membresía', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: Text('Cancela en cualquier momento', style: TextStyle(color: AppColors.textDarkGrey, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  static void _mostrarPlanesMembresia(BuildContext context, ToofastProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(
          left: 32, 
          right: 32, 
          top: 32, 
          bottom: MediaQuery.of(modalContext).viewInsets.bottom + 32
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const Text('Selecciona tu plan 💎', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              _buildPlanTile(context, modalContext, provider, '7 Días', 'Acceso total por una semana', '15 USD'),
              _buildPlanTile(context, modalContext, provider, '1 Mes + 10 Días', 'Nuestra opción más popular', '40 USD', isPopular: true),
              _buildPlanTile(context, modalContext, provider, '6 Meses + 20 Días', 'Ahorro máximo a largo plazo', '200 USD'),
              if (!provider.pruebaUsada && !provider.esPremium) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),
                _buildPruebaGratuitaTile(context, modalContext, provider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPruebaGratuitaTile(BuildContext context, BuildContext modalContext, ToofastProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.premiumGreenStart, AppColors.premiumGreenEnd]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.card_giftcard, color: Colors.white),
        title: const Text('Prueba Gratuita 🎁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('3 días de beneficios Premium sin costo', style: TextStyle(color: Colors.white70, fontSize: 12)),
        onTap: () async {
          Navigator.pop(modalContext);
          int resultado = await provider.activarPruebaGratuita();
          
          if (resultado == 1) {
            mostrarPremiumDialog(context, "¡Prueba de 3 días activada! Disfruta de todos los beneficios Premium.");
          } else if (resultado == -1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Este dispositivo ya ha utilizado su prueba gratuita con otra cuenta."),
                backgroundColor: AppColors.errorRed,
              )
            );
          } else if (resultado == 0) {
            mostrarPremiumDialog(context, "Usted ya ha utilizado su periodo de prueba.");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error al activar la prueba. Inténtalo más tarde."))
            );
          }
        },
      ),
    );
  }

  static Widget _buildPlanTile(BuildContext stableContext, BuildContext modalContext, ToofastProvider provider, String title, String subtitle, String price, {bool isPopular = false}) {
    final bool esPlanActual = provider.planActual == title;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: esPlanActual 
                  ? AppColors.secondary 
                  : (isPopular ? AppColors.primary : AppColors.border),
              width: (isPopular || esPlanActual) ? 2 : 1
          )
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (isPopular) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), 
                child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))
              ),
            ],
            if (esPlanActual) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)), 
                child: const Text('ACTUAL', style: TextStyle(color: AppColors.background, fontSize: 8, fontWeight: FontWeight.bold))
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 12)),
        trailing: Text(price, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w900, fontSize: 16)),
        onTap: () {
          Navigator.pop(modalContext); // Cerramos el modal usando su propio contexto
          if (esPlanActual) {
            mostrarPremiumDialog(stableContext, "Usted ya tiene este plan activo.");
            return;
          }
          _mostrarMetodosPago(stableContext, title, provider);
        },
      ),
    );
  }

  static void _mostrarMetodosPago(BuildContext context, String plan, ToofastProvider provider) {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        padding: EdgeInsets.only(
          left: 32, 
          right: 32, 
          top: 32, 
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 32
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              Text('Pagar Plan: $plan 💳', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              const Text('Selecciona tu método de pago preferido para activar tu membresía.', 
                style: TextStyle(color: AppColors.textLightGrey, fontSize: 14)),
              
              const SizedBox(height: 30),
              
              // Simulación de métodos de pago
              _buildMetodoPagoTile(
                icon: Icons.credit_card, 
                title: 'Tarjeta de Crédito / Débito', 
                subtitle: 'Visa, Mastercard, etc.',
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Cerramos el modal de métodos de pago
                  _procesarPagoStripe(context, plan, provider);
                }
              ),
              _buildMetodoPagoTile(
                icon: Icons.account_balance_wallet_outlined, 
                title: 'Billetera Digital', 
                subtitle: 'Google Pay',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _procesarPagoStripe(context, plan, provider);
                }
              ),
              
              const SizedBox(height: 32),
              
              // Sección de contacto WhatsApp
              Center(
                child: Column(
                  children: [
                    const Text('¿No puedes pagar en línea?', 
                      style: TextStyle(color: AppColors.textLightGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse("https://wa.me/18483843040?text=Hola,%20necesito%20ayuda%20para%20pagar%20el%20plan%20$plan%20de%20Toofast");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF25D366), width: 1)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                            SizedBox(width: 10),
                            Text('Contactar por WhatsApp', 
                              style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMetodoPagoTile({
    required IconData icon, 
    required String title, 
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.border, size: 14),
        onTap: onTap,
      ),
    );
  }

  static void _procesarPagoStripe(BuildContext context, String plan, ToofastProvider provider) async {
    print("🎯 Iniciando procesamiento de Stripe para: $plan");
    
    // 1. Mostrar indicador de carga (Usando root navigator para evitar problemas de contexto)
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    // Mapeo de precios (USD)
    String monto = "15";
    if (plan == '1 Mes + 10 Días') monto = "40";
    if (plan == '6 Meses + 20 Días') monto = "200";

    await StripeService.instance.makePayment(
      amount: monto,
      currency: "usd",
      onPaymentResult: (success) {
        // Cerramos el diálogo de carga usando el mismo contexto de navegación
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (success) {
          provider.activarPlanPremium(plan);
          mostrarPremiumDialog(context, "¡Pago realizado con éxito! Tu plan de $plan ha sido activado.");
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Error de comunicación: No se pudo contactar con el servidor de pagos o la tarjeta fue rechazada. Revise su conexión o use un VPN si está en Cuba."),
                backgroundColor: AppColors.errorRed,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        }
      },
    );
  }

  static Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
            child: Icon(icon, color: AppColors.primary, size: 22)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 4), 
                Text(subtitle, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13, height: 1.3))
              ]
            )
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/feature_title.dart';
import 'main_navigation_screen.dart';

class ConfiguracionBusquedaScreen extends StatefulWidget {
  const ConfiguracionBusquedaScreen({super.key});

  @override
  State<ConfiguracionBusquedaScreen> createState() => _ConfiguracionBusquedaScreenState();
}

class _ConfiguracionBusquedaScreenState extends State<ConfiguracionBusquedaScreen> {
  late TextEditingController _desdeController;
  late TextEditingController _hastaController;
  late TextEditingController _palabraClaveController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ToofastProvider>(context, listen: false);
    _desdeController = TextEditingController(text: provider.precioDesde);
    _hastaController = TextEditingController(text: provider.precioHasta);
    _palabraClaveController = TextEditingController(text: provider.palabraClave);
  }

  @override
  void dispose() {
    _desdeController.dispose();
    _hastaController.dispose();
    _palabraClaveController.dispose();
    super.dispose();
  }

  final Map<String, String> _nombresEsteticosCategorias = {
    'vehiculos': '🚗  Vehículos y Carros',
    'inmobiliaria': '🏠  Casas y Alquileres',
    'tecnologia': '💻  Tecnología y PC',
    'electrodomesticos': '📺  Electrodomésticos',
    'ropa-y-accesorios': '👟  Ropa y Accesorios',
    'familia': '🍼  Artículos para Familia',
    'general': '📦  Compra-Venta General',
    'hogar': '🛋️  Muebles y Hogar',
  };

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    return Scaffold(
      drawer: AppDrawer(provider: toofastProvider),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textGrey),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.bolt, color: AppColors.primary, size: 36),
                        Text('Toofast', 
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Encuentra ofertas en Revolico antes que los demás', 
                      style: TextStyle(color: AppColors.textLightGrey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: AppColors.border)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.arrow_back, color: AppColors.textGrey, size: 20),
                        SizedBox(width: 10),
                        Text('Configuración de búsqueda', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Categoría', style: TextStyle(color: AppColors.textLightGrey, fontSize: 12)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.border)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toofastProvider.categoria,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: toofastProvider.categoriasVisibles.map((String slugReal) {
                            return DropdownMenuItem<String>(
                              value: slugReal,
                              child: Text(_nombresEsteticosCategorias[slugReal] ?? slugReal),
                            );
                          }).toList(),
                          onChanged: (String? nuevoSlug) {
                            if (nuevoSlug != null) {
                              toofastProvider.cambiarCategoria(nuevoSlug);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    FeatureTitle(title: 'Rango de precio (USD)', isLocked: !toofastProvider.esPremium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _desdeController,
                            prefix: 'Desde',
                            enabled: toofastProvider.esPremium,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0), 
                          child: Text('—', style: TextStyle(color: AppColors.textGrey))
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: _hastaController,
                            prefix: 'Hasta',
                            enabled: toofastProvider.esPremium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    FeatureTitle(title: 'Palabra clave (opcional)', isLocked: !toofastProvider.esPremium),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.border)
                      ),
                      child: TextField(
                        controller: _palabraClaveController,
                        enabled: toofastProvider.esPremium,
                        style: TextStyle(
                          color: toofastProvider.esPremium ? Colors.white : Colors.grey, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold
                        ),
                        decoration: InputDecoration(
                          hintText: toofastProvider.esPremium ? 'Ej. Samsung, Smart TV' : 'Bloqueado (Solo Premium 🔒)',
                          hintStyle: const TextStyle(color: AppColors.textDarkGrey, fontSize: 13, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: const Icon(Icons.search, color: AppColors.textDarkGrey, size: 18),
                          suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    FeatureTitle(title: 'Frecuencia de escaneo', isLocked: !toofastProvider.esPremium),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.border)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toofastProvider.esPremium ? toofastProvider.frecuencia : '1hora',
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: [
                            DropdownMenuItem(
                              value: '5min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 5 minutos' : '⏱️  Cada 5 minutos (Premium 🔒)', 
                                style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '10min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 10 minutos' : '⏱️  Cada 10 minutos (Premium 🔒)', 
                                style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '15min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 15 minutos' : '⏱️  Cada 15 minutos (Premium 🔒)', 
                                style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '30min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 30 minutos' : '⏱️  Cada 30 minutos (Premium 🔒)', 
                                style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            const DropdownMenuItem(value: '1hora', child: Text('⏱️  Cada 1 hora')),
                          ],
                          onChanged: (String? nuevoValor) {
                            if (nuevoValor != null && toofastProvider.esPremium) {
                              if (toofastProvider.isEscaneando) {
                                toofastProvider.activarEscaneo(
                                    desde: _desdeController.text,
                                    hasta: _hastaController.text,
                                    categoria: toofastProvider.categoria,
                                    palabraClave: _palabraClaveController.text,
                                    frecuenciaSeleccionada: nuevoValor
                                );
                              } else {
                                toofastProvider.activarEscaneo(
                                    desde: _desdeController.text,
                                    hasta: _hastaController.text,
                                    categoria: toofastProvider.categoria,
                                    palabraClave: _palabraClaveController.text,
                                    frecuenciaSeleccionada: nuevoValor
                                );
                                toofastProvider.detenerEscaneo();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(toofastProvider.isEscaneando ? Icons.stop : Icons.play_arrow, color: Colors.white),
                        label: Text(
                            toofastProvider.isEscaneando ? 'Detener escaneo' : 'Activar escaneo',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: toofastProvider.isEscaneando ? AppColors.errorRed : AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (toofastProvider.isEscaneando) {
                            toofastProvider.detenerEscaneo();
                          } else {
                            toofastProvider.activarEscaneo(
                                desde: _desdeController.text,
                                hasta: _hastaController.text,
                                categoria: toofastProvider.categoria,
                                palabraClave: _palabraClaveController.text,
                                frecuenciaSeleccionada: toofastProvider.frecuencia
                            );

                            FocusScope.of(context).unfocus();

                            final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                            navState?.cambiarAPestana(1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.footerBg, 
                  borderRadius: BorderRadius.circular(10), 
                  border: Border.all(color: AppColors.footerBorder)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.shieldBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Toofast escaneará la categoría seleccionada con el intervalo definido y te notificará si encuentra alguna oferta.', 
                      style: TextStyle(color: Color(0xFF4C6A92), fontSize: 11, height: 1.4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

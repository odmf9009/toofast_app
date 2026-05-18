import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'toofast_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ToofastProvider(),
      child: const ToofastApp(),
    ),
  );
}

class ToofastApp extends StatelessWidget {
  const ToofastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toofast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF00FF66),
          surface: Color(0xFF0F1926),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ConfigracionBusquedaScreen(),
    const EstadoEscaneoScreen(),
    const AlertasOfertasScreen(),
    const GuardadosScreen(),
    const AjustesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B121F),
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: const Color(0xFF55657E),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Guardados'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
    );
  }

  void cambiarAPestana(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

// ====================================================================
// --- PANTALLA 1: CONFIGURACIÓN DE BÚSQUEDA ---
// ====================================================================
class ConfigracionBusquedaScreen extends StatefulWidget {
  const ConfigracionBusquedaScreen({super.key});

  @override
  State<ConfigracionBusquedaScreen> createState() => _ConfigracionBusquedaScreenState();
}

class _ConfigracionBusquedaScreenState extends State<ConfigracionBusquedaScreen> {
  late TextEditingController _desdeController;
  late TextEditingController _hastaController;
  late TextEditingController _palabraClaveController; // 🔍 Controlador para la palabra clave

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
                        Icon(Icons.bolt, color: Color(0xFFFF6B00), size: 36),
                        Text('Toofast', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Encuentra ofertas en Revolico antes que los demás', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D42))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.arrow_back, color: Color(0xFF55657E), size: 20),
                        SizedBox(width: 10),
                        Text('Configuración de búsqueda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Categoría', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toofastProvider.categoria,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F1926),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: toofastProvider.listaCategorias.map((String slugReal) {
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
                    const Text('Rango de precio (USD)', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFieldReal(
                            controller: _desdeController,
                            prefix: 'Desde',
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0), child: Text('—', style: TextStyle(color: Color(0xFF55657E)))),
                        Expanded(
                          child: _buildTextFieldReal(
                            controller: _hastaController,
                            prefix: 'Hasta',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Text('Palabra clave (opcional)', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
                    const SizedBox(height: 8),

                    // 🔍 MODIFICADO: Campo de texto real y editable para la palabra clave
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: TextField(
                        controller: _palabraClaveController,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Ej. Samsung, Smart TV',
                          hintStyle: TextStyle(color: Color(0xFF404E62), fontSize: 13, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: Icon(Icons.search, color: Color(0xFF404E62), size: 18),
                          suffixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text('Frecuencia de escaneo', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toofastProvider.frecuencia,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F1926),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: const [
                            DropdownMenuItem(value: '5min', child: Text('⏱️  Cada 5 minutos')),
                            DropdownMenuItem(value: '10min', child: Text('⏱️  Cada 10 minutos')),
                            DropdownMenuItem(value: '15min', child: Text('⏱️  Cada 15 minutos')),
                            DropdownMenuItem(value: '30min', child: Text('⏱️  Cada 30 minutos')),
                            DropdownMenuItem(value: '1hora', child: Text('⏱️  Cada 1 hora')),
                          ],
                          onChanged: (String? nuevoValor) {
                            if (nuevoValor != null) {
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
                          backgroundColor: toofastProvider.isEscaneando ? const Color(0xFFFF455B) : const Color(0xFFFF6B00),
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
                                palabraClave: _palabraClaveController.text, // 👈 Pasamos el texto real ingresado
                                frecuenciaSeleccionada: toofastProvider.frecuencia
                            );

                            FocusScope.of(context).unfocus();

                            final navState = context.findAncestorStateOfType<_MainNavigationScreenState>();
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
                decoration: BoxDecoration(color: const Color(0xFF091424), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF0E2544))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.shield_outlined, color: Color(0xFF3273CD), size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Toofast escaneará la categoría seleccionada con el intervalo definido y te notificará si encuentra alguna oferta.', style: TextStyle(color: Color(0xFF4C6A92), fontSize: 11, height: 1.4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldReal({required TextEditingController controller, required String prefix}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF070E17),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E2D42))
      ),
      child: Row(
        children: [
          Text('$prefix ', style: const TextStyle(color: Color(0xFF55657E), fontSize: 11)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// --- PANTALLA 2: ESTADO DEL ESCANEO ---
// ====================================================================
class EstadoEscaneoScreen extends StatefulWidget {
  const EstadoEscaneoScreen({super.key});

  @override
  State<EstadoEscaneoScreen> createState() => _EstadoEscaneoScreenState();
}

class _EstadoEscaneoScreenState extends State<EstadoEscaneoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatearTiempo(int segundosTotales) {
    int minutos = segundosTotales ~/ 60;
    int segundos = segundosTotales % 60;
    String minStr = minutos.toString().padLeft(2, '0');
    String segStr = segundos.toString().padLeft(2, '0');
    return '$minStr:$segStr min';
  }

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    if (!toofastProvider.isEscaneando && _animationController.isAnimating) {
      _animationController.stop();
    } else if (toofastProvider.isEscaneando && !_animationController.isAnimating) {
      _animationController.repeat();
    }

    String frecuenciaTexto = toofastProvider.frecuencia
        .replaceAll('min', ' minutos')
        .replaceAll('1hora', '1 hora');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Color(0xFF55657E)),
        title: const Center(child: Text('Estado del escaneo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: const [Icon(Icons.more_vert, color: Color(0xFF55657E)), SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 210, height: 210, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0A201D).withOpacity(0.3), border: Border.all(color: toofastProvider.isEscaneando ? const Color(0xFF00FF66).withOpacity(0.15) : Colors.grey.withOpacity(0.15), width: 1.5))),
                  Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: toofastProvider.isEscaneando ? const Color(0xFF00FF66).withOpacity(0.15) : Colors.grey.withOpacity(0.15), width: 1.5))),
                  Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: toofastProvider.isEscaneando ? const Color(0xFF00FF66).withOpacity(0.15) : Colors.grey.withOpacity(0.15), width: 1.5))),

                  if (toofastProvider.isEscaneando)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animationController.value * 2 * math.pi,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [const Color(0xFF00FF66).withOpacity(0.3), const Color(0xFF00FF66).withOpacity(0.0)], stops: const [0.2, 1.0])),
                          ),
                        );
                      },
                    ),
                  Icon(Icons.search, color: toofastProvider.isEscaneando ? const Color(0xFF00FF66) : Colors.grey, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: toofastProvider.isEscaneando ? const Color(0xFF0C241E) : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: toofastProvider.isEscaneando ? const Color(0xFF00FF66).withOpacity(0.3) : Colors.grey.withOpacity(0.3))
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: toofastProvider.isEscaneando ? const Color(0xFF00FF66) : Colors.grey, size: 10),
                  const SizedBox(width: 10),
                  Text(toofastProvider.isEscaneando ? 'Escaneando...' : 'Radar Inactivo', style: TextStyle(color: toofastProvider.isEscaneando ? const Color(0xFF00FF66) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))
                ],
              ),
            ),
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D42))),
              child: Column(
                children: [
                  _buildDataRow('Categoría:', toofastProvider.categoria),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow('Rango de precio:', '\$${toofastProvider.precioDesde} - \$${toofastProvider.precioHasta}'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  // 🔍 Mostrar la palabra clave activa en el resumen
                  _buildDataRow('Filtro de palabra:', toofastProvider.palabraClave.isEmpty ? 'Ninguno' : '"${toofastProvider.palabraClave}"'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow('Frecuencia:', 'Cada $frecuenciaTexto'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow('Estado de motor:', toofastProvider.isEscaneando ? 'Corriendo' : 'Detenido'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow(
                      'Próxima revisión:',
                      toofastProvider.isEscaneando ? _formatearTiempo(toofastProvider.proximaRevision) : '— —',
                      isNeon: toofastProvider.isEscaneando
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isNeon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF55657E), fontSize: 14)),
        Text(value, style: TextStyle(color: isNeon ? const Color(0xFFFF6B00) : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// ====================================================================
// --- PANTALLA 3: OPORTUNIDADES ENCONTRADAS ---
// ====================================================================
class AlertasOfertasScreen extends StatelessWidget {
  const AlertasOfertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);
    final ofertas = toofastProvider.ofertasEncontradas;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Color(0xFF55657E)),
        title: const Center(child: Text('Oportunidades encontradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B00), width: 1)
            ),
            child: Center(
              child: Text('${ofertas.length} HITS', style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: !toofastProvider.isEscaneando
          ? const Center(child: Text('El radar está apagado.\nActívalo para empezar a cazar ofertas.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF55657E), fontSize: 14)))
          : ofertas.isEmpty
          ? Center(
        child: Text(
          toofastProvider.palabraClave.isEmpty
              ? 'Escaneando Revolico...\nNo hay ofertas en este rango todavía.'
              : 'Escaneando Revolico...\nNo hay anuncios que coincidan con "${toofastProvider.palabraClave}".',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF55657E), fontSize: 14),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: ofertas.length,
        itemBuilder: (context, index) {
          final item = ofertas[index];
          final bool guardado = toofastProvider.esFavorito(item['id']!);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final String? urlString = item['enlace'];
              if (urlString != null && urlString.isNotEmpty) {
                final Uri url = Uri.parse(urlString);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D42))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(item['titulo']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 10),
                      Text('\$${item['precio']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00FF66))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item['detalles']!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A90), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF55657E), size: 14),
                          const SizedBox(width: 6),
                          Text(item['tiempo']!, style: const TextStyle(color: Color(0xFF55657E), fontSize: 11)),
                          const SizedBox(width: 12),
                          const Icon(Icons.open_in_new, color: Color(0xFF40526B), size: 13),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                            guardado ? Icons.favorite : Icons.favorite_border,
                            color: guardado ? const Color(0xFFFF6B00) : const Color(0xFF55657E),
                            size: 20
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          toofastProvider.toggleFavorito(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(guardado ? 'Eliminado de guardados' : 'Guardado en favoritos local'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====================================================================
// --- PANTALLA 4: ANUNCIOS GUARDADOS ---
// ====================================================================
class GuardadosScreen extends StatelessWidget {
  const GuardadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);
    final favoritos = toofastProvider.ofertasGuardadas;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Color(0xFF55657E)),
        title: const Center(child: Text('Anuncios guardados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
      body: favoritos.isEmpty
          ? const Center(
        child: Text(
          'No tienes anuncios guardados.\nToca el corazón en las ofertas cazadas para retenerlas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF55657E), fontSize: 14),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: favoritos.length,
        itemBuilder: (context, index) {
          final item = favoritos[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final String? urlString = item['enlace'];
              if (urlString != null && urlString.isNotEmpty) {
                final Uri url = Uri.parse(urlString);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Este favorito no cuenta con enlace registrado.")),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D42))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(item['titulo']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 10),
                      Text('\$${item['precio']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00FF66))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item['detalles']!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A90), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(item['tiempo']!, style: const TextStyle(color: Color(0xFF55657E), fontSize: 11)),
                          const SizedBox(width: 12),
                          const Icon(Icons.open_in_new, color: Color(0xFF40526B), size: 13),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF455B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          toofastProvider.toggleFavorito(item);
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====================================================================
// --- PANTALLA 5: AJUSTES ---
// ====================================================================
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const Icon(Icons.menu, color: Color(0xFF55657E)), title: const Center(child: Text('Ajustes del sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
      body: const Center(child: Text('Configuración del sistema lista', style: TextStyle(color: Color(0xFF55657E)))),
    );
  }
}
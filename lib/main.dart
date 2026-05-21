import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'toofast_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ToofastProvider(),
      child: const ToofastApp(),
    ),
  );
}

class ToofastApp extends StatefulWidget {
  const ToofastApp({super.key});

  @override
  State<ToofastApp> createState() => _ToofastAppState();
}

class _ToofastAppState extends State<ToofastApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toofast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070E17),
        colorScheme: const ColorScheme.dark(
          primary: const Color(0xFFFF6B00),
          secondary: const Color(0xFF00FF66),
          surface: const Color(0xFF0F1926),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- GLOBALS & HELPERS ---

Widget _buildPlaceholder() {
  return Container(
    width: 85,
    height: 85,
    color: const Color(0xFF070E17),
    child: const Icon(Icons.image_outlined, color: Color(0xFF1E2D42), size: 30),
  );
}

void _mostrarPremiumDialog(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0F1926),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('💎 Función Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
          onPressed: () {
            Navigator.pop(context);
            final navState = context.findAncestorStateOfType<_MainNavigationScreenState>();
            navState?.cambiarAPestana(4); // Ir a Perfil
          },
          child: const Text('Mejorar ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Widget _buildDrawer(BuildContext context, ToofastProvider provider) {
  return Drawer(
    backgroundColor: const Color(0xFF0F1926),
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
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7A90)),
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
                    leading: const Icon(Icons.category_outlined, color: Color(0xFFFF6B00)),
                    title: const Text(
                      'Categorías',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    iconColor: const Color(0xFFFF6B00),
                    collapsedIconColor: Colors.white70,
                    childrenPadding: const EdgeInsets.only(left: 12),
                    initiallyExpanded: false,
                    children: [
                      // Opción Seleccionar Todo
                      CheckboxListTile(
                        title: const Text('✨  Seleccionar Todo (All)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        value: provider.categoriasVisibles.length == provider.listaCategorias.length,
                        activeColor: const Color(0xFFFF6B00),
                        checkColor: Colors.white,
                        onChanged: (bool? value) {
                          provider.toggleTodasCategorias(value ?? true);
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      const Divider(color: Color(0xFF1E2D42), indent: 16, endIndent: 16),
                      
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
                          title: Text(nombresEsteticos[slug] ?? slug, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          value: estaVisible,
                          activeColor: const Color(0xFFFF6B00),
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

// ====================================================================
// --- NAVIGATION SCREEN ---
// ====================================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _autoNavegacionRealizada = false;

  final List<Widget> _screens = [
    const ConfigracionBusquedaScreen(),
    const EstadoEscaneoScreen(),
    const AlertasOfertasScreen(),
    const GuardadosScreen(),
    const PerfilScreen(),
  ];

  void cambiarAPestana(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    if (!toofastProvider.isEscaneando && _autoNavegacionRealizada) {
      _autoNavegacionRealizada = false;
    }

    if (_currentIndex == 1 && 
        toofastProvider.isEscaneando && 
        toofastProvider.ofertasEncontradas.isNotEmpty && 
        !_autoNavegacionRealizada) {
      
      _autoNavegacionRealizada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() { _currentIndex = 2; });
      });
    }

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
            if (index == 1) _autoNavegacionRealizada = true;
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
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
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
      drawer: _buildDrawer(context, toofastProvider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF55657E)),
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
                    _buildFeatureTitle('Rango de precio (USD)', !toofastProvider.esPremium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFieldReal(
                            controller: _desdeController,
                            prefix: 'Desde',
                            enabled: toofastProvider.esPremium,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0), child: Text('—', style: TextStyle(color: Color(0xFF55657E)))),
                        Expanded(
                          child: _buildTextFieldReal(
                            controller: _hastaController,
                            prefix: 'Hasta',
                            enabled: toofastProvider.esPremium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    _buildFeatureTitle('Palabra clave (opcional)', !toofastProvider.esPremium),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: TextField(
                        controller: _palabraClaveController,
                        enabled: toofastProvider.esPremium,
                        style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: toofastProvider.esPremium ? 'Ej. Samsung, Smart TV' : 'Bloqueado (Solo Premium 🔒)',
                          hintStyle: const TextStyle(color: Color(0xFF404E62), fontSize: 13, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: const Icon(Icons.search, color: Color(0xFF404E62), size: 18),
                          suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildFeatureTitle('Frecuencia de escaneo', !toofastProvider.esPremium),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toofastProvider.esPremium ? toofastProvider.frecuencia : '1hora',
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F1926),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: [
                            DropdownMenuItem(
                              value: '5min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 5 minutos' : '⏱️  Cada 5 minutos (Premium 🔒)', style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '10min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 10 minutos' : '⏱️  Cada 10 minutos (Premium 🔒)', style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '15min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 15 minutos' : '⏱️  Cada 15 minutos (Premium 🔒)', style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
                            ),
                            DropdownMenuItem(
                              value: '30min', 
                              enabled: toofastProvider.esPremium,
                              child: Text(toofastProvider.esPremium ? '⏱️  Cada 30 minutos' : '⏱️  Cada 30 minutos (Premium 🔒)', style: TextStyle(color: toofastProvider.esPremium ? Colors.white : Colors.grey)),
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
                                palabraClave: _palabraClaveController.text,
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

  Widget _buildTextFieldReal({required TextEditingController controller, required String prefix, bool enabled = true}) {
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
              enabled: enabled,
              keyboardType: TextInputType.number,
              style: TextStyle(color: enabled ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildFeatureTitle(String title, bool isLocked) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
        if (isLocked) ...[
          const SizedBox(width: 6),
          const Icon(Icons.lock, color: Colors.yellow, size: 12),
        ],
      ],
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
      drawer: _buildDrawer(context, toofastProvider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Center(child: Text('Estado del escaneo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: const [Icon(Icons.more_vert, color: Color(0xFF55657E)), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  _buildDataRow('Filtro de palabra:', toofastProvider.palabraClave.isEmpty ? 'Ninguno' : '"${toofastProvider.palabraClave}"'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow('Frecuencia:', 'Cada $frecuenciaTexto'),
                  const Divider(color: Color(0xFF1E2D42), height: 24),
                  _buildDataRow('Escaneos realizados:', '${toofastProvider.cantidadEscaneos}'),
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
      drawer: _buildDrawer(context, toofastProvider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: SafeArea(
        child: !toofastProvider.isEscaneando
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
            final bool isLocked = !toofastProvider.esPremium && index >= 5;

            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: isLocked ? 5 : 0, sigmaY: isLocked ? 5 : 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                    onTap: isLocked ? null : () async {
                      final String? urlString = item['enlace'];
                      if (urlString != null && urlString.isNotEmpty) {
                        final Uri url = Uri.parse(urlString);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D42))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (item['imagen'] != null && item['imagen']!.isNotEmpty)
                                ? Image.network(
                                    item['imagen']!,
                                    width: 85,
                                    height: 85,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                            ),
                          ),

                          Expanded(
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, color: Color(0xFFFFD700), size: 13),
                                              const SizedBox(width: 4),
                                              Text('${item['tiempo'] ?? ''}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10)),
                                              if (item['visitas'] != null && item['visitas']!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF00FF66), size: 13),
                                                const SizedBox(width: 4),
                                                Text('${item['visitas']}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10)),
                                              ],
                                              const SizedBox(width: 8),
                                              const Icon(Icons.open_in_new, color: Color(0xFFFF6B00), size: 12),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, color: Color(0xFF3273CD), size: 13),
                                              const SizedBox(width: 4),
                                              Flexible(child: Text('${item['ubicacion'] ?? ''}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10, overflow: TextOverflow.ellipsis))),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          guardado ? Icons.favorite : Icons.favorite_border,
                                          color: guardado ? const Color(0xFFFF6B00) : const Color(0xFF55657E),
                                          size: 20
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: isLocked ? null : () {
                                        if (!guardado && !toofastProvider.esPremium && toofastProvider.ofertasGuardadas.isNotEmpty) {
                                          _mostrarPremiumDialog(context, "Los usuarios FREE solo pueden guardar 1 favorito. ¡Actualiza para favoritos ilimitados!");
                                          return;
                                        }
                                        toofastProvider.toggleFavorito(item);
                                      },
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (isLocked)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.yellow, size: 24),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () {
                              final navState = context.findAncestorStateOfType<_MainNavigationScreenState>();
                              navState?.cambiarAPestana(4);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Desbloquear con Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
      drawer: _buildDrawer(context, toofastProvider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Center(child: Text('Anuncios guardados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: [
          if (favoritos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFFF455B)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0F1926),
                    title: const Text('Eliminar todo', style: TextStyle(color: Colors.white)),
                    content: const Text('¿Estás seguro de que quieres borrar todos tus favoritos?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          toofastProvider.limpiarTodosFavoritos();
                          Navigator.pop(context);
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF455B))),
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
            ? const Center(child: Text('No tienes anuncios guardados.\nToca el corazón en las ofertas cazadas para retenerlas.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF55657E), fontSize: 14)))
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
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D42))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['imagen'] != null && item['imagen']!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['imagen']!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: const Color(0xFF070E17), child: const Icon(Icons.image_not_supported, color: Color(0xFF1E2D42))),
                        ),
                      ),
                    ),

                  Expanded(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Color(0xFFFFD700), size: 13),
                                      const SizedBox(width: 4),
                                      Text('${item['tiempo'] ?? ''}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10)),
                                      if (item['visitas'] != null && item['visitas']!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF00FF66), size: 13),
                                        const SizedBox(width: 4),
                                        Text('${item['visitas']}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10)),
                                      ],
                                      const SizedBox(width: 8),
                                      const Icon(Icons.open_in_new, color: Color(0xFFFF6B00), size: 12),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Color(0xFF3273CD), size: 13),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text('${item['ubicacion'] ?? ''}', style: const TextStyle(color: Color(0xFF55657E), fontSize: 10, overflow: TextOverflow.ellipsis))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF455B), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () { toofastProvider.toggleFavorito(item); },
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

// ====================================================================
// --- PANTALLA 5: PERFIL ---
// ====================================================================

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, toofastProvider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Center(child: Text('Mi Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: const [Icon(Icons.edit_outlined, color: Color(0xFF55657E)), SizedBox(width: 16)],
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
                            backgroundColor: const Color(0xFF0F1926),
                            backgroundImage: (toofastProvider.fotoPerfilUrl != null && !toofastProvider.estaCargandoFoto)
                                ? (toofastProvider.fotoPerfilUrl!.startsWith('data:image') 
                                    ? MemoryImage(base64Decode(toofastProvider.fotoPerfilUrl!.split(',')[1])) as ImageProvider
                                    : NetworkImage(toofastProvider.fotoPerfilUrl!))
                                : null,
                            child: toofastProvider.estaCargandoFoto 
                                ? const CircularProgressIndicator(color: Color(0xFF00FF66))
                                : (toofastProvider.fotoPerfilUrl == null 
                                    ? Text(toofastProvider.usuario!.displayName?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white))
                                    : null),
                          ),
                        ),
                        // Ícono de Cámara para editar
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => toofastProvider.cambiarFotoPerfil(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF1E2D42), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        // Badge de Premium (Rayo)
                        if (toofastProvider.esPremium)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF00FF66), shape: BoxShape.circle),
                              child: const Icon(Icons.bolt, size: 16, color: Color(0xFF070E17)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(toofastProvider.usuario!.displayName ?? 'Usuario', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(toofastProvider.usuario!.email, style: const TextStyle(fontSize: 13, color: Color(0xFF55657E))),
                  ] else ...[
                    const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0F1926), child: Icon(Icons.person_outline, size: 50, color: Colors.white24)),
                    const SizedBox(height: 20),
                    const Text('Inicia sesión para sincronizar', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try { await toofastProvider.iniciarSesionGoogle(); } catch (e) {
                          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e'))); }
                        }
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Entrar con Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1926), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1E2D42)))),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildStatCard('Favoritos', '${toofastProvider.ofertasGuardadas.length}', Icons.favorite_border)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Vistos', '${toofastProvider.ofertasEncontradas.length}', Icons.remove_red_eye_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _mostrarBeneficiosPremium(context, toofastProvider),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: toofastProvider.esPremium 
                      ? [const Color(0xFF004D2C), const Color(0xFF00331A)]
                      : [const Color(0xFFFF6B00), const Color(0xFFFF9E00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (toofastProvider.esPremium ? const Color(0xFF00FF66) : const Color(0xFFFF6B00)).withOpacity(0.3),
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
            _buildSectionTitle('Preferencias de App'),
            _buildSettingTile(Icons.notifications_none, 'Notificaciones de radar', toofastProvider.notificacionesHabilitadas ? 'Habilitadas' : 'Deshabilitadas', true, value: toofastProvider.notificacionesHabilitadas, onChanged: (v) => toofastProvider.setNotificaciones(v)),
            _buildSettingTile(Icons.history, 'Limpiar historial', 'Borrar búsquedas pasadas', false),
            const SizedBox(height: 24),
            _buildSectionTitle('Cuenta y Seguridad'),
            _buildSettingTile(Icons.lock_outline, 'Privacidad', 'Gestionar mis datos', false, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const DatosUsuarioScreen())); }),
            _buildSettingTile(Icons.info_outline, 'Acerca de Toofast', 'Versión 1.0.2', false),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Personalización'),
            _buildSettingTile(
              Icons.category_outlined, 
              'Filtrar Categorías', 
              'Elegir qué mostrar en el Home', 
              false, 
              onTap: () {
                Scaffold.of(context).openDrawer();
              }
            ),

            if (toofastProvider.esAdmin) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Administración'),
              _buildSettingTile(
                Icons.admin_panel_settings_outlined, 
                'Panel de Control', 
                'Usuarios y actividad en vivo', 
                false, 
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
                  icon: const Icon(Icons.logout, color: Color(0xFFFF455B), size: 20),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFFF455B), fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFFFF455B).withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  void _mostrarBeneficiosPremium(BuildContext context, ToofastProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Color(0xFF0F1926), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFF1E2D42), borderRadius: BorderRadius.circular(2)))),
            const Text('Beneficios Premium 💎', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Lleva tu búsqueda de ofertas al siguiente nivel', style: TextStyle(color: Color(0xFF6B7A90), fontSize: 14)),
            const SizedBox(height: 32),
            _buildBenefitItem(Icons.bolt, 'Escaneos en tiempo real', 'Sin límites de tiempo entre búsquedas.'),
            _buildBenefitItem(Icons.search, 'Filtros avanzados', 'Búsqueda por palabras clave y rango de precios.'),
            _buildBenefitItem(Icons.notifications_active, 'Notificaciones instantáneas', 'Entérate de las ofertas en el momento exacto.'),
            _buildBenefitItem(Icons.visibility, 'Resultados desbloqueados', 'Accede a los 20 resultados de cada escaneo.'),
            _buildBenefitItem(Icons.favorite, 'Favoritos ilimitados', 'Guarda todas las ofertas que quieras.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!provider.estaLogueado) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, inicia sesión para adquirir la membresía.'), backgroundColor: Color(0xFFFF455B)));
                    return;
                  }

                  if (provider.esPremium) {
                    if (provider.planActual == '6 Meses + 20 Días') {
                      Navigator.pop(context);
                      _mostrarPremiumDialog(context, "Usted ha adquirido la membresía máxima. ¡Gracias por tu apoyo!");
                      return;
                    }
                    // Si tiene un plan menor, dejamos que vea los planes para "mejorar"
                  }

                  Navigator.pop(context);
                  _mostrarPlanesMembresia(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: const Color(0xFFFF6B00).withOpacity(0.4)),
                child: Text(provider.esPremium ? 'Mejorar membresía' : 'Obtener membresía', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('Cancela en cualquier momento', style: TextStyle(color: Color(0xFF404E62), fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _mostrarPlanesMembresia(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Color(0xFF0F1926), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFF1E2D42), borderRadius: BorderRadius.circular(2)))),
            const Text('Selecciona tu plan 💎', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildPlanTile(context, '7 Días', 'Acceso total por una semana', '15 USD'),
            _buildPlanTile(context, '1 Mes + 10 Días', 'Nuestra opción más popular', '40 USD', isPopular: true),
            _buildPlanTile(context, '6 Meses + 20 Días', 'Ahorro máximo a largo plazo', '200 USD'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile(BuildContext context, String title, String subtitle, String price, {bool isPopular = false}) {
    final provider = Provider.of<ToofastProvider>(context, listen: false);
    final bool esPlanActual = provider.planActual == title;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: const Color(0xFF070E17),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: esPlanActual 
                  ? const Color(0xFF00FF66) 
                  : (isPopular ? const Color(0xFFFF6B00) : const Color(0xFF1E2D42)),
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
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(20)), child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
            ],
            if (esPlanActual) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00FF66), borderRadius: BorderRadius.circular(20)), child: const Text('ACTUAL', style: TextStyle(color: Color(0xFF070E17), fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
        trailing: Text(price, style: const TextStyle(color: Color(0xFF00FF66), fontWeight: FontWeight.w900, fontSize: 16)),
        onTap: () {
          Navigator.pop(context);
          if (esPlanActual) {
            _mostrarPremiumDialog(context, "Usted ya tiene este plan activo.");
            return;
          }
          provider.activarPlanPremium(title);
          _mostrarPremiumDialog(context, "¡Felicidades! Has cambiado al plan de $title.");
        },
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFFFF6B00), size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 13, height: 1.3))])),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D42))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6B00), size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF55657E), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0, left: 4), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF404E62), letterSpacing: 1.2))));
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, bool isSwitch, {bool? value, Function(bool)? onChanged, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F1926), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2D42))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF070E17), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFF55657E), size: 20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF55657E), fontSize: 12)),
        trailing: isSwitch ? Switch(value: value ?? true, onChanged: onChanged, activeColor: const Color(0xFFFF6B00)) : const Icon(Icons.arrow_forward_ios, color: Color(0xFF1E2D42), size: 14),
        onTap: onTap,
      ),
    );
  }
}

// ====================================================================
// --- NUEVA PANTALLA: DATOS DEL USUARIO ---
// ====================================================================

class DatosUsuarioScreen extends StatelessWidget {
  const DatosUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToofastProvider>(context);
    final user = provider.usuario;

    return Scaffold(
      drawer: _buildDrawer(context, provider),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          Text(label, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E2D42)),
        ],
      ),
    );
  }
}

// ====================================================================
// --- NUEVA PANTALLA: PANEL DE ADMINISTRACIÓN ---
// ====================================================================
class PanelAdminUsuariosScreen extends StatelessWidget {
  const PanelAdminUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Panel de Administración', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF6B00),
            labelColor: Color(0xFFFF6B00),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Registrados', icon: Icon(Icons.people_outline)),
              Tab(text: 'En Línea', icon: Icon(Icons.bolt)),
            ],
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: toofastProvider.streamUsuarios,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error al cargar usuarios'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final allDocs = snapshot.data!.docs;
              final onlineDocs = allDocs.where((d) {
                final data = d.data() as Map;
                if (data['ultima_conexion'] == null) return false;
                final lastSeen = (data['ultima_conexion'] as Timestamp).toDate();
                return DateTime.now().difference(lastSeen).inMinutes < 5;
              }).toList();

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF0F1926),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAdminStat('Registrados', '${allDocs.length}'),
                        _buildAdminStat('Premium', '${allDocs.where((d) => (d.data() as Map)['esPremium'] == true).length}'),
                        _buildAdminStat('En Línea', '${onlineDocs.length}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Pestaña 1: Todos los registrados
                        _buildUserList(context, allDocs, toofastProvider),
                        // Pestaña 2: Solo los que están en línea
                        _buildUserList(context, onlineDocs, toofastProvider),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<QueryDocumentSnapshot> docs, ToofastProvider toofastProvider) {
    if (docs.isEmpty) {
      return const Center(child: Text('No hay usuarios en esta sección', style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final bool isPremium = data['esPremium'] ?? false;
        final lastSeen = (data['ultima_conexion'] as Timestamp?)?.toDate();
        final bool isOnline = lastSeen != null && DateTime.now().difference(lastSeen).inMinutes < 5;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1926),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2D42)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: (data['foto'] != null && data['foto'].isNotEmpty)
                        ? (data['foto'].startsWith('data:image')
                            ? MemoryImage(base64Decode(data['foto'].split(',')[1])) as ImageProvider
                            : NetworkImage(data['foto']))
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: (data['foto'] == null || data['foto'].isEmpty)
                        ? Text(data['nombre']?[0].toUpperCase() ?? '?', style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F1926), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        if (data['esAdmin'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 14),
                        ],
                      ],
                    ),
                    Text(data['email'] ?? 'Sin email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (isPremium)
                const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 18),
              
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: const Color(0xFF0F1926),
                onSelected: (action) async {
                  final userId = docs[index].id;
                  if (action == 'DEACTIVATE') {
                    await toofastProvider.adminDesactivarPremium(userId);
                  } else if (action == 'TOGGLE_ADMIN') {
                    await toofastProvider.adminAsignarAdmin(userId, !(data['esAdmin'] == true));
                  } else {
                    await toofastProvider.adminActivarPremium(userId, action);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Acción realizada para ${data['nombre']}')),
                    );
                  }
                },
                itemBuilder: (context) {
                  final currentPlan = data['planActual'];
                  final bool userIsAdmin = data['esAdmin'] == true;
                  
                  return [
                    PopupMenuItem(
                      value: '7 Días', 
                      child: Text('🎁 Activar 7 Días', style: TextStyle(color: (isPremium && currentPlan == '7 Días') ? const Color(0xFF00FF66) : Colors.white))
                    ),
                    PopupMenuItem(
                      value: '1 Mes + 10 Días', 
                      child: Text('💎 Activar 1 Mes', style: TextStyle(color: (isPremium && currentPlan == '1 Mes + 10 Días') ? const Color(0xFF00FF66) : Colors.white))
                    ),
                    PopupMenuItem(
                      value: '6 Meses + 20 Días', 
                      child: Text('👑 Activar 6 Meses', style: TextStyle(color: (isPremium && currentPlan == '6 Meses + 20 Días') ? const Color(0xFF00FF66) : Colors.white))
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'DEACTIVATE', 
                      child: Text('🚫 Desactivar Premium', style: TextStyle(color: Color(0xFFFF455B)))
                    ),
                    PopupMenuItem(
                      value: 'TOGGLE_ADMIN', 
                      child: Text(userIsAdmin ? '👤 Quitar Admin' : '🔑 Hacer Admin', style: TextStyle(color: userIsAdmin ? Colors.orange : Colors.blue))
                    ),
                  ];
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

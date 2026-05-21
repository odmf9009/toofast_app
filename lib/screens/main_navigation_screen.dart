import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import 'configuracion_busqueda_screen.dart';
import 'estado_escaneo_screen.dart';
import 'alertas_ofertas_screen.dart';
import 'guardados_screen.dart';
import 'perfil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _autoNavegacionRealizada = false;

  final List<Widget> _screens = [
    const ConfiguracionBusquedaScreen(),
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
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
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

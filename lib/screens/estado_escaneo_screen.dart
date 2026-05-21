import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/data_row_item.dart';
import '../utils/app_utils.dart';

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
      drawer: AppDrawer(provider: toofastProvider),
      appBar: AppBar(
        title: const Center(child: Text('Estado del escaneo', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        actions: const [Icon(Icons.more_vert, color: AppColors.textGrey), SizedBox(width: 16)],
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
                  Container(
                    width: 210, 
                    height: 210, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: AppColors.radarCircle.withOpacity(0.3), 
                      border: Border.all(
                        color: toofastProvider.isEscaneando 
                          ? AppColors.secondary.withOpacity(0.15) 
                          : Colors.grey.withOpacity(0.15), 
                        width: 1.5
                      )
                    )
                  ),
                  Container(
                    width: 140, 
                    height: 140, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(
                        color: toofastProvider.isEscaneando 
                          ? AppColors.secondary.withOpacity(0.15) 
                          : Colors.grey.withOpacity(0.15), 
                        width: 1.5
                      )
                    )
                  ),
                  Container(
                    width: 70, 
                    height: 70, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(
                        color: toofastProvider.isEscaneando 
                          ? AppColors.secondary.withOpacity(0.15) 
                          : Colors.grey.withOpacity(0.15), 
                        width: 1.5
                      )
                    )
                  ),

                  if (toofastProvider.isEscaneando)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animationController.value * 2 * math.pi,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              gradient: SweepGradient(
                                colors: [
                                  AppColors.secondary.withOpacity(0.3), 
                                  AppColors.secondary.withOpacity(0.0)
                                ], 
                                stops: const [0.2, 1.0]
                              )
                            ),
                          ),
                        );
                      },
                    ),
                  Icon(Icons.search, 
                    color: toofastProvider.isEscaneando ? AppColors.secondary : Colors.grey, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: toofastProvider.isEscaneando ? AppColors.radarActive : AppColors.radarInactive,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: toofastProvider.isEscaneando 
                      ? AppColors.secondary.withOpacity(0.3) 
                      : Colors.grey.withOpacity(0.3)
                  )
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, 
                    color: toofastProvider.isEscaneando ? AppColors.secondary : Colors.grey, size: 10),
                  const SizedBox(width: 10),
                  Text(toofastProvider.isEscaneando ? 'Escaneando...' : 'Radar Inactivo', 
                    style: TextStyle(
                      color: toofastProvider.isEscaneando ? AppColors.secondary : Colors.grey, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 14
                    )
                  )
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
                children: [
                  DataRowItem(label: 'Categoría:', value: toofastProvider.categoria),
                  const Divider(height: 24),
                  DataRowItem(label: 'Rango de precio:', 
                    value: '\$${toofastProvider.precioDesde} - \$${toofastProvider.precioHasta}'),
                  const Divider(height: 24),
                  DataRowItem(label: 'Filtro de palabra:', 
                    value: toofastProvider.palabraClave.isEmpty ? 'Ninguno' : '"${toofastProvider.palabraClave}"'),
                  const Divider(height: 24),
                  DataRowItem(label: 'Frecuencia:', value: 'Cada $frecuenciaTexto'),
                  const Divider(height: 24),
                  DataRowItem(label: 'Escaneos realizados:', value: '${toofastProvider.cantidadEscaneos}'),
                  const Divider(height: 24),
                  DataRowItem(label: 'Estado de motor:', 
                    value: toofastProvider.isEscaneando ? 'Corriendo' : 'Detenido'),
                  const Divider(height: 24),
                  DataRowItem(
                      label: 'Próxima revisión:',
                      value: toofastProvider.isEscaneando 
                        ? AppUtils.formatearTiempo(toofastProvider.proximaRevision) 
                        : '— —',
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
}

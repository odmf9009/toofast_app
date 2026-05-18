import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ToofastProvider extends ChangeNotifier {
  bool _isEscaneando = false;
  bool get isEscaneando => _isEscaneando;

  String _categoria = 'vehiculos';
  String get categoria => _categoria;

  String _precioDesde = '';
  String _precioHasta = '';
  String get precioDesde => _precioDesde;
  String get precioHasta => _precioHasta;

  // 🔍 Nueva variable para almacenar la palabra clave
  String _palabraClave = '';
  String get palabraClave => _palabraClave;

  String _frecuencia = '5min';
  String get frecuencia => _frecuencia;

  Timer? _timer;
  int _proximaRevisionEnSegundos = 300;
  int get proximaRevision => _proximaRevisionEnSegundos;

  List<Map<String, String>> _ofertasEncontradas = [];
  List<Map<String, String>> get ofertasEncontradas => _ofertasEncontradas;

  List<Map<String, String>> _ofertasGuardadas = [];
  List<Map<String, String>> get ofertasGuardadas => _ofertasGuardadas;

  final Set<String> _idsNotificados = {};
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  List<String> get listaCategorias => [
    'vehiculos',
    'inmobiliaria',
    'tecnologia',
    'electrodomesticos',
    'ropa-y-accesorios',
    'familia',
    'general',
    'hogar'
  ];

  ToofastProvider() {
    _cargarDatosLocales();
    _inicializarNotificaciones();
  }

  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> _cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    _precioDesde = prefs.getString('precioDesde') ?? '';
    _precioHasta = prefs.getString('precioHasta') ?? '';
    _categoria = prefs.getString('categoria') ?? 'vehiculos';
    _palabraClave = prefs.getString('palabraClave') ?? ''; // Cargar palabra clave

    final String? favoritosJson = prefs.getString('favoritos');
    if (favoritosJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritosJson);
      _ofertasGuardadas = decoded.map((item) => Map<String, String>.from(item)).toList();
    }
    notifyListeners();
  }

  void cambiarCategoria(String nuevaCategoria) {
    _categoria = nuevaCategoria;
    notifyListeners();
  }

  int _convertirFrecuenciaASegundos(String valor) {
    switch (valor) {
      case '1hora': return 3600;
      case '30min': return 1800;
      case '15min': return 900;
      case '10min': return 600;
      case '5min':  return 300;
      default:      return 300;
    }
  }

  void activarEscaneo({
    required String desde,
    required String hasta,
    required String categoria,
    required String palabraClave, // Recibe la palabra desde la UI
    required String frecuenciaSeleccionada,
  }) async {
    _isEscaneando = true;
    _precioDesde = desde;
    _precioHasta = hasta;
    _categoria = categoria;
    _palabraClave = palabraClave.trim();
    _frecuencia = frecuenciaSeleccionada;

    int segundosBase = _convertirFrecuenciaASegundos(frecuenciaSeleccionada);
    _proximaRevisionEnSegundos = segundosBase;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('precioDesde', desde);
    await prefs.setString('precioHasta', hasta);
    await prefs.setString('categoria', categoria);
    await prefs.setString('palabraClave', _palabraClave); // Guardar localmente

    _idsNotificados.clear();
    _ejecutarScrapingReal();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_proximaRevisionEnSegundos > 0) {
        _proximaRevisionEnSegundos--;
        notifyListeners();
      } else {
        _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);
        _ejecutarScrapingReal();
      }
    });
  }

  Future<void> _ejecutarScrapingReal() async {
    print("🌐 [Radar Real] Conectando a la sección oficial de $_categoria mediante navegador oculto...");

    try {
      final String urlOficial = 'https://www.revolico.com/search?category=$_categoria';
      late HeadlessInAppWebView headlessWebView;
      bool yaProcesado = false;

      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(
            url: WebUri(urlOficial),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            }
        ),
        onLoadStop: (controller, url) async {
          if (yaProcesado) return;
          yaProcesado = true;

          print("🔓 [Radar Real] ¡Navegador cargó la página con éxito! Extrayendo datos...");

          final String? html = await controller.getHtml();

          if (html != null && html.contains('id="__NEXT_DATA__"')) {
            try {
              final String parteInicial = html.split('id="__NEXT_DATA__"')[1].split('>')[1];
              String jsonString = parteInicial.split('</script>')[0].trim();
              if (jsonString.endsWith('</script')) {
                jsonString = jsonString.replaceAll('</script', '').trim();
              }

              final Map<String, dynamic> datosEstructurados = jsonDecode(jsonString);
              final props = datosEstructurados['props'] ?? {};
              final pageProps = props['pageProps'] ?? {};
              final Map<String, dynamic> apolloState = pageProps['__APOLLO_STATE__'] ?? {};

              List<Map<String, String>> resultadosFiltrados = [];
              List<Map<String, String>> nuevosChollosParaNotificar = [];

              int min = int.tryParse(_precioDesde) ?? 0;
              int max = int.tryParse(_precioHasta) ?? 999999;

              apolloState.forEach((key, value) {
                if (value is Map) {
                  if (value.containsKey('price') && value.containsKey('title')) {

                    String idAnuncio = value['id']?.toString() ?? key;
                    String tituloAnuncio = value['title']?.toString() ?? 'Sin título';
                    String precioAnuncioStr = value['price']?.toString() ?? '0';
                    String detallesAnuncio = value['description']?.toString() ?? '';

                    if (precioAnuncioStr.contains('.')) {
                      precioAnuncioStr = precioAnuncioStr.split('.')[0];
                    }

                    int precioAnuncio = int.tryParse(precioAnuncioStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                    // 🎯 LÓGICA FILTRO PALABRA CLAVE
                    bool coincidePalabra = true;
                    if (_palabraClave.isNotEmpty) {
                      // Creamos una expresión regular insensible a mayúsculas/minúsculas
                      RegExp query = RegExp(_palabraClave, caseSensitive: false);
                      bool enTitulo = query.hasMatch(tituloAnuncio);
                      bool enDetalles = query.hasMatch(detallesAnuncio);

                      if (!enTitulo && !enDetalles) {
                        coincidePalabra = false; // No cumple con el criterio del usuario
                      }
                    }

                    if (precioAnuncio >= min && precioAnuncio <= max && coincidePalabra) {
                      print("🚗 [Hit Encontrado] $tituloAnuncio -> \$$precioAnuncio");

                      String permalink = value['permalink']?.toString() ?? '';
                      String urlDirecta = "";

                      if (permalink.isNotEmpty) {
                        urlDirecta = "https://www.revolico.com${permalink.startsWith('/') ? '' : '/'}$permalink";
                      } else {
                        urlDirecta = "https://www.revolico.com/search?category=$_categoria";
                      }

                      var ofertaMap = {
                        'id': idAnuncio,
                        'titulo': tituloAnuncio,
                        'precio': precioAnuncio.toString(),
                        'tiempo': 'Reciente',
                        'detalles': detallesAnuncio,
                        'enlace': urlDirecta,
                      };

                      resultadosFiltrados.add(ofertaMap);

                      if (!_idsNotificados.contains(idAnuncio)) {
                        nuevosChollosParaNotificar.add(ofertaMap);
                      }
                    }
                  }
                }
              });

              if (nuevosChollosParaNotificar.isNotEmpty && _isEscaneando) {
                _dispararNotificacion(nuevosChollosParaNotificar.length);
                for (var chollo in nuevosChollosParaNotificar) {
                  _idsNotificados.add(chollo['id']!);
                }
              }

              _ofertasEncontradas = resultadosFiltrados;
              print("🎯 [Radar Real] Procesados ${resultadosFiltrados.length} anuncios filtrados en Apollo.");
              notifyListeners();

            } catch (e) {
              print("⚠️ Error analizando los datos dentro del navegador: $e");
            }
          } else {
            print("⚠️ El navegador abrió la web pero no encontró el bloque __NEXT_DATA__.");
          }

          try {
            await headlessWebView.dispose();
          } catch (e) {
            print("Aviso de cierre de motor: $e");
          }
        },
        onLoadError: (controller, url, code, message) {
          print("❌ Error en el navegador oculto: $message (Código: $code)");
          if (!yaProcesado) {
            headlessWebView.dispose();
          }
        },
      );

      await headlessWebView.run();

    } catch (e) {
      print("❌ Error crítico en el motor invisible: $e");
    }
  }

  Future<void> _dispararNotificacion(int cantidad) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'toofast_radar_channel', 'Alertas de Radar',
      channelDescription: 'Notificaciones cuando se encuentran ofertas',
      importance: Importance.max, priority: Priority.high, showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    String msg = _palabraClave.isEmpty
        ? 'Toofast cazó $cantidad oferta(s) en tu rango.'
        : 'Toofast cazó $cantidad oferta(s) de "$_palabraClave".';

    await _notificationsPlugin.show(0, '⚡ ¡Filtro Activado!', msg, platformChannelSpecifics);
  }

  void toggleFavorito(Map<String, String> oferta) async {
    final existe = _ofertasGuardadas.any((item) => item['id'] == oferta['id']);
    if (existe) { _ofertasGuardadas.removeWhere((item) => item['id'] == oferta['id']); }
    else { _ofertasGuardadas.add(oferta); }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritos', jsonEncode(_ofertasGuardadas));
  }

  bool esFavorito(String id) => _ofertasGuardadas.any((item) => item['id'] == id);

  void detenerEscaneo() {
    _isEscaneando = false;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
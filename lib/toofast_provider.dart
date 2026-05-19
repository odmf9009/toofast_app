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
      // 🚀 EVITAR CACHÉ: Añadimos un timestamp único a la URL
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String urlOficial = 'https://www.revolico.com/search?category=$_categoria&t=$timestamp';
      
      late HeadlessInAppWebView headlessWebView;
      bool yaProcesado = false;

      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(
            url: WebUri(urlOficial),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            }
        ),
        initialSettings: InAppWebViewSettings(
          cacheMode: CacheMode.LOAD_NO_CACHE, // 🛑 Forzar carga sin caché
          clearCache: true,                   // 🧹 Limpiar caché al iniciar
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

              // 1. OBTENER LA LISTA ORDENADA DESDE EL JSON (Súper fiable)
              List<dynamic> listaOrdenadaRefs = [];
              try {
                final rootQuery = apolloState['ROOT_QUERY'] ?? {};
                String searchKey = rootQuery.keys.firstWhere((k) => k.startsWith('search'), orElse: () => "");
                if (searchKey.isNotEmpty) {
                  listaOrdenadaRefs = rootQuery[searchKey]['results'] ?? [];
                }
              } catch (e) { print("Error buscando lista ordenada en JSON: $e"); }

              Iterable<dynamic> itemsParaProcesar = listaOrdenadaRefs.isNotEmpty 
                  ? listaOrdenadaRefs 
                  : apolloState.values;

              int contadorHits = 0;
              for (var item in itemsParaProcesar) {
                if (contadorHits >= 20) break;
                
                var value = (item is Map && item.containsKey('__ref')) 
                    ? apolloState[item['__ref']] 
                    : item;

                if (value is Map && value.containsKey('price') && value.containsKey('title')) {
                  // Filtro: Destacados
                  bool esDestacado = value['isFeatured'] == true || value['isPremium'] == true;
                  if (esDestacado) continue;

                  String idAnuncio = value['id']?.toString() ?? "";
                  String titulo = value['title']?.toString() ?? 'Sin título';
                  String precioStr = value['price']?.toString() ?? '0';
                  int precioNum = int.tryParse(precioStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

                  // Filtro: Rango de precio
                  if (precioNum < min || precioNum > max) continue;

                  // Filtro: Palabra clave
                  bool coincidePalabra = true;
                  if (_palabraClave.isNotEmpty) {
                    RegExp query = RegExp(_palabraClave, caseSensitive: false);
                    if (!query.hasMatch(titulo)) coincidePalabra = false;
                  }
                  if (!coincidePalabra) continue;

                  // --- 🕵️‍♂️ EXTRACCIÓN DEL TIEMPO REAL DESDE EL HTML (Híbrido) ---
                  String tiempo = "Reciente";
                  String ubicacion = "Cuba";
                  String fotos = "0";

                  try {
                    // Limpiamos el ID para asegurarnos de que sea solo el número
                    String idNumerico = idAnuncio.replaceAll(RegExp(r'\D'), '');
                    
                    // Buscamos el bloque li que contiene el enlace con ese ID
                    // El patrón busca: <li ... href="...-ID" ... </li>
                    RegExp regBloque = RegExp('<li[^>]*data-cy="adRow"[^>]*>.*?href="[^"]*-$idNumerico".*?</li>', dotAll: true);
                    var matchBloque = regBloque.firstMatch(html!);
                    
                    if (matchBloque != null) {
                      String bloqueHtml = matchBloque.group(0)!;
                      
                      // Extraer Tiempo (<time>hace 5 minutos</time>)
                      RegExp rTime = RegExp(r'<time>([^<]+)</time>');
                      var mTime = rTime.firstMatch(bloqueHtml);
                      if (mTime != null) {
                        tiempo = mTime.group(1)!.trim();
                      }

                      // Extraer Ubicación (<span>Plaza, La Habana</span>)
                      // Buscamos el primer span que tenga el formato "Texto, Texto"
                      RegExp rLoc = RegExp(r'<span>([^<]+,\s+[^<]+)</span>');
                      var mLoc = rLoc.firstMatch(bloqueHtml);
                      if (mLoc != null) {
                        ubicacion = mLoc.group(1)!.trim();
                      }

                      // Extraer Fotos (data-cy="adPhoto")
                      RegExp rPhotos = RegExp(r'data-cy="adPhoto"[^>]*>.*?(\d+)', dotAll: true);
                      var mPhotos = rPhotos.firstMatch(bloqueHtml);
                      if (mPhotos != null) {
                        fotos = mPhotos.group(1)!;
                      }
                    }
                  } catch (e) { print("Error extrayendo datos HTML para $idAnuncio: $e"); }

                  contadorHits++;
                  String permalink = value['permalink']?.toString() ?? '';
                  String urlDirecta = "https://www.revolico.com${permalink.startsWith('/') ? '' : '/'}$permalink";

                  var ofertaMap = {
                    'id': idAnuncio,
                    'titulo': titulo,
                    'precio': precioNum.toString(),
                    'tiempo': tiempo,
                    'ubicacion': ubicacion,
                    'fotos': fotos,
                    'visitas': '',
                    'enlace': urlDirecta,
                    'imagen': '',
                    'detalles': value['description']?.toString() ?? '',
                  };

                  resultadosFiltrados.add(ofertaMap);
                  if (!_idsNotificados.contains(idAnuncio)) {
                    nuevosChollosParaNotificar.add(ofertaMap);
                  }
                }
              }

              if (nuevosChollosParaNotificar.isNotEmpty && _isEscaneando) {
                _dispararNotificacion(nuevosChollosParaNotificar.length);
                for (var chollo in nuevosChollosParaNotificar) {
                  _idsNotificados.add(chollo['id']!);
                }
              }

              _ofertasEncontradas = resultadosFiltrados;
              notifyListeners();

              // 🚀 ENRIQUECER EN SEGUNDO PLANO (Imágenes y Visitas)
              _enriquecerDatosEnSegundoPlano(resultadosFiltrados);

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

  // 🕵️‍♂️ FUNCIÓN MAESTRA: Entra al anuncio y extrae TODO con precisión quirúrgica (Actualizado Estructura 2025)
  Future<void> _enriquecerDatosEnSegundoPlano(List<Map<String, String>> ofertas) async {
    for (var i = 0; i < ofertas.length; i++) {
      if (!_isEscaneando) break;
      
      final url = ofertas[i]['enlace'];
      if (url == null || url.isEmpty || !url.startsWith('http')) continue;

      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));
        
        if (response.statusCode == 200) {
          String html = response.body;

          // 1. IMAGEN: og:image (Súper fiable)
          RegExp regImg = RegExp(r'<meta property="og:image" content="([^"]+)"');
          var matchImg = regImg.firstMatch(html);
          if (matchImg != null) ofertas[i]['imagen'] = matchImg.group(1) ?? "";

          // 2. EXTRACCIÓN FLEXIBLE (Múltiples patrones)

          // A. Tiempo Real: NO SOBREESCRIBIR (Lo tomamos de la lista oficial)
          // Se mantiene el valor capturado en _ejecutarScrapingReal

          // B. Ubicación Exacta (Detecta el formato "Municipio, Provincia")
          RegExp regLoc = RegExp(r'<span>([^<]+,\s+[^<]+)</span>|data-cy="adLocation"[^>]*>([^<]+)</p>');
          var matchLoc = regLoc.firstMatch(html);
          if (matchLoc != null) {
            ofertas[i]['ubicacion'] = (matchLoc.group(1) ?? matchLoc.group(2))!.trim();
          }

          // C. Visitas
          RegExp regVisits = RegExp(r'data-cy="adViewsLabel"[^>]*>([^<]+)</p>|(\d+)\s+visitas');
          var matchVisits = regVisits.firstMatch(html);
          if (matchVisits != null) {
            ofertas[i]['visitas'] = (matchVisits.group(1) ?? matchVisits.group(2))!.trim();
            if (!ofertas[i]['visitas']!.contains("visitas")) {
              ofertas[i]['visitas'] = "${ofertas[i]['visitas']} visitas";
            }
          }

          // D. Cantidad de Fotos (Detecta data-cy="adPhoto" o texto "X foto")
          RegExp regPhotos = RegExp(r'data-cy="adPhoto"[^>]*>([^<]*\d+[^<]*)</span>|(\d+)\s+foto[s]?');
          var matchPhotos = regPhotos.firstMatch(html);
          if (matchPhotos != null) {
            String raw = (matchPhotos.group(1) ?? matchPhotos.group(2))!;
            // Extraer solo el número si hay texto extra
            RegExp soloNum = RegExp(r'(\d+)');
            var matchNum = soloNum.firstMatch(raw);
            if (matchNum != null) ofertas[i]['fotos'] = matchNum.group(1)!;
          }
          
          print("✅ [OK] ${ofertas[i]['titulo']} -> ${ofertas[i]['tiempo']}");
          notifyListeners(); 
        }
      } catch (e) {
        print("Error enriqueciendo anuncio ${ofertas[i]['id']}: $e");
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
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
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/constants/categories.dart';

class ToofastProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isEscaneando = false;
  bool get isEscaneando => _isEscaneando;
  
  bool _appEnPrimerPlano = true; // 🔋 Para ahorro de energía

  // 🔑 Servicios Refactorizados
  final AuthService _auth = AuthService.instance;
  final DatabaseService _db = DatabaseService.instance;

  // 🔑 Variables de Autenticación
  GoogleSignInAccount? _usuario;
  GoogleSignInAccount? get usuario => _usuario;
  bool get estaLogueado => _usuario != null;

  String? _fotoPerfilUrl;
  String? get fotoPerfilUrl => _fotoPerfilUrl ?? _usuario?.photoUrl;

  bool _estaCargandoFoto = false;
  bool get estaCargandoFoto => _estaCargandoFoto;

  // 💎 Estado de Suscripción (TEMPORARILY DISABLED - COMING SOON: Forced to true for all users)
  bool _esPremium = true; 
  bool get esPremium => true; // Forced getter
  
  DateTime? _vencimientoPremium;
  DateTime? get vencimientoPremium => _vencimientoPremium;
  String? _planActual;
  String? get planActual => _planActual;
  
  bool _pruebaUsada = false;
  bool get pruebaUsada => _pruebaUsada;

  int _totalUsuarios = 0;
  int get totalUsuarios => _totalUsuarios;
  int _totalEscaneosGlobales = 0;
  int get totalEscaneosGlobales => _totalEscaneosGlobales;
  
  List<String> _bannerUrls = [];
  List<String> get bannerUrls => _bannerUrls;

  Map<String, List<Map<String, String>>> _subcategorias = CategoryConstants.defaultSubcategories;
  Map<String, List<Map<String, String>>> get subcategorias => _subcategorias;

  Map<String, String> _nombresCategorias = CategoryConstants.categoryNames;
  Map<String, String> get nombresCategorias => _nombresCategorias;

  bool _soyAdminEnFirestore = false;
  bool get esAdmin => _usuario?.email == 'krvillamil1990@gmail.com' || _soyAdminEnFirestore;

  int _cantidadEscaneos = 0;
  int get cantidadEscaneos => _cantidadEscaneos;

  Stream<QuerySnapshot> get streamUsuarios => _db.streamTodosUsuarios();

  String get tiempoRestantePremium {
    if (_vencimientoPremium == null) return "Expirado";
    final diff = _vencimientoPremium!.difference(DateTime.now());
    if (diff.isNegative) return "Expirado";
    
    if (diff.inDays > 0) return "${diff.inDays}d ${diff.inHours % 24}h";
    if (diff.inHours > 0) return "${diff.inHours}h ${diff.inMinutes % 60}m";
    return "${diff.inMinutes}m";
  }

  // 🔔 Preferencias de Notificaciones
  bool _notificacionesHabilitadas = true;
  bool get notificacionesHabilitadas => _notificacionesHabilitadas;

  // 🤖 Opciones Premium: Auto-guardar
  bool _autoGuardarAlertas = false;
  bool get autoGuardarAlertas => _autoGuardarAlertas;

  int _maxAutoGuardados = 5;
  int get maxAutoGuardados => _maxAutoGuardados;

  String _categoria = 'vehiculos';
  String get categoria => _categoria;

  String _subcategoria = '';
  String get subcategoria => _subcategoria;

  String _precioDesde = '';
  String _precioHasta = '';
  String get precioDesde => _precioDesde;
  String get precioHasta => _precioHasta;

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

  List<String> get listaCategorias => CategoryConstants.mainCategories;

  List<String> _categoriasVisibles = List.from(CategoryConstants.mainCategories);
  List<String> get categoriasVisibles => _categoriasVisibles;

  ToofastProvider() {
    WidgetsBinding.instance.addObserver(this); 
    _cargarDatosLocales();
    _inicializarNotificaciones();
    _revisarLoginSilencioso();
    _escucharEstadisticasGlobales();
    Timer(const Duration(seconds: 5), () {
      if (esAdmin) {
        _actualizarBannersGlobalesDesdeApp();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appEnPrimerPlano = (state == AppLifecycleState.resumed);
  }

  void _escucharEstadisticasGlobales() {
    _db.streamTodosUsuarios().listen((snapshot) {
      _totalUsuarios = snapshot.docs.length;
      notifyListeners();
    });

    _db.streamStatsGlobales().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _totalEscaneosGlobales = data['total_escaneos'] ?? 0;
        notifyListeners();
      }
    });

    _db.streamBanners().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> urls = data['urls'] ?? [];
        _bannerUrls = urls.cast<String>();
        notifyListeners();
      }
    });

    _db.streamCategorias().listen((doc) {
      if (doc.exists) {
        final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>) ?? {};
        Map<String, List<Map<String, String>>> actualizadas = {};
        data.forEach((key, value) {
          if (value is List && key != 'ultima_actualizacion') {
            actualizadas[key] = value.map((item) => Map<String, String>.from(item)).toList();
          }
        });
        if (actualizadas.isNotEmpty) {
          _subcategorias = actualizadas;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _revisarLoginSilencioso() async {
    _usuario = await _auth.signInSilently();
    if (_usuario != null) {
      await _sincronizarUsuarioDesdeFirestore();
    }
    notifyListeners();
  }

  Future<void> _sincronizarUsuarioDesdeFirestore() async {
    if (_usuario == null) return;
    try {
      final doc = await _db.getUsuario(_usuario!.id);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _fotoPerfilUrl = data['foto'];
        // Note: _esPremium is forced to true globally, but we keep sync for future use
        _planActual = data['planActual'];
        _soyAdminEnFirestore = data['esAdmin'] == true;
        _pruebaUsada = data['pruebaUsada'] == true;
        if (data['favoritos'] != null) {
          final List<dynamic> favs = data['favoritos'];
          _ofertasGuardadas = favs.map((item) => Map<String, String>.from(item)).toList();
        }
        String? vencimientoStr = data['vencimientoPremium'];
        if (vencimientoStr != null && vencimientoStr.isNotEmpty) {
          _vencimientoPremium = DateTime.parse(vencimientoStr);
        }
      }
      await _actualizarUsuarioEnFirestore();
    } catch (e) {
      print("Error sincronizando: $e");
    }
  }

  Future<void> _actualizarUsuarioEnFirestore() async {
    if (_usuario == null) return;
    try {
      await _db.saveUsuario(_usuario!.id, {
        'id': _usuario!.id,
        'nombre': _usuario!.displayName,
        'email': _usuario!.email,
        'foto': _usuario!.photoUrl,
        'esPremium': true, // Forced for now
        'vencimientoPremium': _vencimientoPremium?.toIso8601String(),
        'planActual': _planActual,
        'pruebaUsada': _pruebaUsada,
        'esAdmin': esAdmin,
        'favoritos': _ofertasGuardadas,
        'ultima_conexion': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  Future<void> iniciarSesionGoogle() async {
    try {
      _usuario = await _auth.signIn();
      if (_usuario != null) {
        await _sincronizarUsuarioDesdeFirestore();
        notifyListeners();
        await _db.saveUsuario(_usuario!.id, {'fecha_registro': FieldValue.serverTimestamp()});
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    _usuario = null;
    _fotoPerfilUrl = null;
    _vencimientoPremium = null;
    _planActual = null;
    _ofertasGuardadas = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vencimientoPremium');
    await prefs.remove('planActual');
    await prefs.remove('favoritos');
    notifyListeners();
  }

  Future<void> cambiarFotoPerfil() async {
    if (_usuario == null) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 300);
    if (image != null) {
      _estaCargandoFoto = true;
      notifyListeners();
      try {
        final bytes = await image.readAsBytes();
        String base64Image = base64Encode(bytes);
        String dataUrl = "data:image/jpeg;base64,$base64Image";
        await _db.saveUsuario(_usuario!.id, {'foto': dataUrl});
        _fotoPerfilUrl = dataUrl;
      } catch (e) {
        print("❌ Error al guardar foto: $e");
      } finally {
        _estaCargandoFoto = false;
        notifyListeners();
      }
    }
  }

  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  void toggleVisibilidadCategoria(String slug) async {
    if (_categoriasVisibles.contains(slug)) {
      if (_categoriasVisibles.length > 1) {
        _categoriasVisibles.remove(slug);
        if (_categoria == slug) _categoria = _categoriasVisibles.first;
      }
    } else {
      _categoriasVisibles.add(slug);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categoriasVisibles', _categoriasVisibles);
  }

  void seleccionarSoloUnaCategoria(String slug) async {
    _categoriasVisibles = [slug];
    _categoria = slug;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categoriasVisibles', _categoriasVisibles);
    await prefs.setString('categoria', _categoria);
  }

  void toggleTodasCategorias(bool seleccionar) async {
    _categoriasVisibles = seleccionar ? List.from(listaCategorias) : [listaCategorias.first];
    if (!seleccionar) _categoria = listaCategorias.first;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categoriasVisibles', _categoriasVisibles);
  }

  Future<void> _cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    _precioDesde = prefs.getString('precioDesde') ?? '';
    _precioHasta = prefs.getString('precioHasta') ?? '';
    _categoria = prefs.getString('categoria') ?? 'vehiculos';
    _subcategoria = prefs.getString('subcategoria_seleccionada') ?? '';
    _palabraClave = prefs.getString('palabraClave') ?? '';
    _notificacionesHabilitadas = prefs.getBool('notificacionesHabilitadas') ?? true;
    _autoGuardarAlertas = prefs.getBool('autoGuardarAlertas') ?? false;
    _maxAutoGuardados = prefs.getInt('maxAutoGuardados') ?? 5;
    _planActual = prefs.getString('planActual');
    _pruebaUsada = prefs.getBool('pruebaUsada') ?? false;
    _cantidadEscaneos = prefs.getInt('cantidadEscaneos') ?? 0;
    final savedCats = prefs.getStringList('categoriasVisibles');
    if (savedCats != null) {
      _categoriasVisibles = savedCats.where((slug) => listaCategorias.contains(slug)).toList();
      if (_categoriasVisibles.isEmpty) _categoriasVisibles = List.from(listaCategorias);
    }
    if (!_categoriasVisibles.contains(_categoria)) _categoria = _categoriasVisibles.first;
    notifyListeners();
  }

  void cambiarCategoria(String nuevaCategoria) async {
    _categoria = nuevaCategoria;
    _subcategoria = '';
    _palabraClave = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoria', nuevaCategoria);
    await prefs.setString('palabraClave', '');
  }

  void cambiarSubcategoria(String nuevaSub) async {
    _subcategoria = nuevaSub;
    _palabraClave = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subcategoria_seleccionada', nuevaSub);
    await prefs.setString('palabraClave', '');
  }

  void setNotificaciones(bool valor) async {
    _notificacionesHabilitadas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacionesHabilitadas', valor);
  }

  void setAutoGuardar(bool valor) async {
    _autoGuardarAlertas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoGuardarAlertas', valor);
  }

  void setMaxAutoGuardados(int valor) async {
    _maxAutoGuardados = valor.clamp(1, 10);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxAutoGuardados', _maxAutoGuardados);
  }

  Future<void> activarPlanPremium(String plan) async {
    _planActual = plan;
    DateTime ahora = DateTime.now();
    if (plan == '7 Días') _vencimientoPremium = ahora.add(const Duration(days: 7));
    else if (plan == '1 Mes + 10 Días') _vencimientoPremium = ahora.add(const Duration(days: 40));
    else if (plan == '6 Meses + 20 Días') _vencimientoPremium = ahora.add(const Duration(days: 200));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vencimientoPremium', _vencimientoPremium!.toIso8601String());
    await prefs.setString('planActual', _planActual!);
    await _actualizarUsuarioEnFirestore();
  }

  Future<int> activarPruebaGratuita() async {
    if (_usuario == null || _pruebaUsada) return 0;
    try {
      final deviceInfo = DeviceInfoPlugin();
      String? deviceId;
      if (Platform.isAndroid) deviceId = (await deviceInfo.androidInfo).id;
      else if (Platform.isIOS) deviceId = (await deviceInfo.iosInfo).identifierForVendor;
      if (deviceId == null) return -2;
      final deviceDoc = await _db.getDispositivoPrueba(deviceId);
      if (deviceDoc.exists) return -1;
      _pruebaUsada = true;
      _planActual = 'Prueba 3 Días';
      _vencimientoPremium = DateTime.now().add(const Duration(days: 3));
      await _db.registerDispositivoPrueba(deviceId, {
        'fecha': FieldValue.serverTimestamp(),
        'usuario_id': _usuario!.id,
        'email': _usuario!.email,
      });
      notifyListeners();
      await _actualizarUsuarioEnFirestore();
      return 1;
    } catch (e) { return -2; }
  }

  Future<void> adminActivarPremium(String userId, String plan) async {
    if (!esAdmin) return;
    DateTime ahora = DateTime.now();
    DateTime vencimiento;
    if (plan == '7 Días') vencimiento = ahora.add(const Duration(days: 7));
    else if (plan == '1 Mes + 10 Días') vencimiento = ahora.add(const Duration(days: 40));
    else if (plan == '6 Meses + 20 Días') vencimiento = ahora.add(const Duration(days: 200));
    else vencimiento = ahora.add(const Duration(days: 7));

    await _db.saveUsuario(userId, {
      'esPremium': true,
      'planActual': plan,
      'vencimientoPremium': vencimiento.toIso8601String(),
    });
  }

  Future<void> adminDesactivarPremium(String userId) async {
    if (!esAdmin) return;
    await _db.saveUsuario(userId, {
      'esPremium': false,
      'planActual': null,
      'vencimientoPremium': null,
    });
  }

  Future<void> adminAsignarAdmin(String userId, bool setAdmin) async {
    if (!esAdmin) return;
    await _db.saveUsuario(userId, {'esAdmin': setAdmin});
  }

  void activarEscaneo({
    required String desde,
    required String hasta,
    required String categoria,
    required String palabraClave,
    required String frecuenciaSeleccionada,
  }) async {
    _isEscaneando = true;
    
    // Always use full filters since Premium is forced to true
    _precioDesde = desde;
    _precioHasta = hasta;
    _palabraClave = palabraClave.trim();
    _frecuencia = frecuenciaSeleccionada;
    
    _categoria = categoria;
    _cantidadEscaneos++;
    _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);
    _incrementarEstadisticasGlobales();
    notifyListeners();
    _idsNotificados.clear();
    _ejecutarScrapingReal();
    _actualizarNotificacionFija();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cantidadEscaneos % 30 == 0 && _proximaRevisionEnSegundos == 5) _actualizarNotificacionFija();
      if (_proximaRevisionEnSegundos > 0) {
        _proximaRevisionEnSegundos--;
        if (_appEnPrimerPlano) notifyListeners();
      } else {
        _cantidadEscaneos++;
        _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);
        _ejecutarScrapingReal();
      }
    });
  }

  Future<void> _ejecutarScrapingReal() async {
    List<Map<String, String>> acumulados = [];
    List<Map<String, String>> nuevos = [];
    print("🚀 [Radar] Iniciando búsqueda exhaustiva (5 páginas max)...");

    for (int i = 1; i <= 5; i++) {
      if (!_isEscaneando) break;
      print("📄 Escaneando página $i...");
      final results = await _obtenerResultadosDePagina(i);
      
      for (var o in results) {
        if (!acumulados.any((x) => x['id'] == o['id'])) {
          acumulados.add(o);
          if (!_idsNotificados.contains(o['id'])) nuevos.add(o);
        }
      }
      // Meta: 10 with keyword, 20 without
      if (acumulados.length >= (_palabraClave.isNotEmpty ? 10 : 20)) break;
    }

    if (acumulados.isNotEmpty) {
      _ofertasEncontradas = acumulados;
      if (nuevos.isNotEmpty && _isEscaneando) {
        _dispararNotificacion(nuevos.length);
        if (_autoGuardarAlertas) { // Enabled for all temporarily
          int count = 0;
          for (var n in nuevos) {
            if (count >= _maxAutoGuardados) break;
            if (!_ofertasGuardadas.any((f) => f['id'] == n['id'])) { _ofertasGuardadas.add(n); count++; }
          }
          if (count > 0 && estaLogueado) _actualizarUsuarioEnFirestore();
        }
        for (var n in nuevos) _idsNotificados.add(n['id']!);
      }
      notifyListeners();
      _enriquecerDatosEnSegundoPlano(acumulados);
    }
  }

  Future<List<Map<String, String>>> _obtenerResultadosDePagina(int pageNum) async {
    final completer = Completer<List<Map<String, String>>>();
    String sub = _subcategoria;
    if (sub.isNotEmpty && !sub.startsWith(_categoria)) sub = '$_categoria-$sub';
    String url = 'https://www.revolico.com/search?category=$_categoria${sub.isNotEmpty ? "&subcategory=$sub" : ""}&page=$pageNum';

    try {
      HeadlessInAppWebView? webView;
      bool done = false;
      webView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          cacheMode: CacheMode.LOAD_NO_CACHE,
          clearCache: true,
        ),
        onLoadStop: (controller, url) async {
          if (done) return;
          done = true;
          final html = await controller.getHtml();
          List<Map<String, String>> res = [];
          if (html != null) {
            try {
              // 🧪 EXTRACCIÓN ROBUSTA POR REGEX
              final regexData = RegExp(r'<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>');
              final match = regexData.firstMatch(html);
              
              if (match != null) {
                String json = match.group(1)!.trim();
                final data = jsonDecode(json);
                final apollo = data['pageProps']?['__APOLLO_STATE__'] ?? data['props']?['pageProps']?['__APOLLO_STATE__'] ?? {};
                
                List<dynamic> items = [];
                final Map<String, dynamic> root = Map<String, dynamic>.from(apollo['ROOT_QUERY'] ?? {});
                String searchKey = "";
                for (var key in root.keys) { if (key.toString().startsWith('search')) { searchKey = key.toString(); break; } }

                if (searchKey.isNotEmpty) items = root[searchKey]['results'] ?? [];
                if (items.isEmpty) {
                   apollo.forEach((k, v) { 
                     if (v is Map && v.containsKey('title') && v.containsKey('price')) items.add(v); 
                   });
                }
                
                int min = int.tryParse(_precioDesde) ?? 0;
                int max = int.tryParse(_precioHasta) ?? 999999;

                for (var i in items) {
                  var v = (i is Map && i.containsKey('__ref')) ? apollo[i['__ref']] : i;
                  if (v is Map && v.containsKey('price') && v.containsKey('title')) {
                    if (v['isFeatured'] == true || v['isPremium'] == true) continue;
                    
                    String titulo = v['title']?.toString() ?? '';
                    String descripcion = v['description']?.toString() ?? '';
                    
                    // 💰 MANEJO DE PRECIO
                    String pRaw = v['price']?.toString() ?? '0';
                    String priceClean = pRaw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
                    double pDouble = double.tryParse(priceClean) ?? 0;
                    int p = pDouble.floor();

                    // 🚫 FILTRO DE PRECIO: Omitir anuncios con precio 0, 1 o fuera de rango
                    if (p <= 1 || p < min || p > max) continue;

                    if (_palabraClave.isNotEmpty) {
                      String keyword = _palabraClave.toLowerCase().trim();
                      if (!titulo.toLowerCase().contains(keyword) && !descripcion.toLowerCase().contains(keyword)) continue;
                    }

                    String permalink = v['permalink']?.toString() ?? '';
                    res.add({
                      'id': v['id']?.toString() ?? '',
                      'titulo': titulo,
                      'precio': p.toString(),
                      'tiempo': 'Reciente',
                      'ubicacion': 'Cuba',
                      'enlace': "https://www.revolico.com${permalink.startsWith('/') ? '' : '/'}$permalink",
                      'imagen': '',
                      'detalles': descripcion,
                    });
                  }
                }
              }
            } catch (e) { print("Error parseando página $pageNum: $e"); }
          }
          completer.complete(res);
          await webView?.dispose();
        },
      );
      await webView.run();
    } catch (e) { completer.complete([]); }
    return completer.future;
  }

  Future<void> _enriquecerDatosEnSegundoPlano(List<Map<String, String>> ofertas) async {
    for (var i = 0; i < ofertas.length; i++) {
      if (!_isEscaneando) break;
      try {
        final resp = await http.get(Uri.parse(ofertas[i]['enlace']!)).timeout(const Duration(seconds: 7));
        if (resp.statusCode == 200) {
          String h = resp.body;
          var mImg = RegExp(r'<meta property="og:image" content="([^"]+)"').firstMatch(h);
          if (mImg != null) ofertas[i]['imagen'] = mImg.group(1)!;
          
          // 📍 EXTRACCIÓN DE LOCALIDAD MEJORADA (Municipio, Provincia)
          // Intento 1: Por data-cy (más preciso)
          var mLoc1 = RegExp(r'data-cy="adLocation"[^>]*>([^<]+)</p>').firstMatch(h);
          // Intento 2: Por span con formato "Texto, Texto"
          var mLoc2 = RegExp(r'<span>([^<]+,\s+[^<]+)</span>').firstMatch(h);
          
          if (mLoc1 != null) {
            ofertas[i]['ubicacion'] = mLoc1.group(1)!.trim();
          } else if (mLoc2 != null) {
            ofertas[i]['ubicacion'] = mLoc2.group(1)!.trim();
          }

          var mWA = RegExp(r'https://wa\.me/(\d+)').firstMatch(h);
          if (mWA != null) ofertas[i]['whatsapp'] = mWA.group(1)!;
          var mTel = RegExp(r'href="tel:(\+?\d+)"').firstMatch(h);
          if (mTel != null) ofertas[i]['telefono'] = mTel.group(1)!;
        }
      } catch (e) {}
      if (i % 3 == 0 || i == ofertas.length - 1) notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _actualizarBannersGlobalesDesdeApp() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('stats').doc('banners').get();
      if (doc.exists) {
        final Timestamp? ts = doc.data()?['ultima_actualizacion'];
        if (ts != null && DateTime.now().difference(ts.toDate()).inHours < 24) return;
      }
      late HeadlessInAppWebView webView;
      bool done = false;
      webView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://www.revolico.com/")),
        onLoadStop: (controller, url) async {
          if (done) return;
          done = true;
          final h = await controller.getHtml();
          if (h != null) {
            var matches = RegExp(r'https://pic\.revolico\.com/pics/[a-zA-Z0-9._-]+\.jpg').allMatches(h);
            Map<String, String> unique = {};
            for (var m in matches) {
              String u = m.group(0)!;
              String id = u.split('/').last.split('_').first;
              if (!unique.containsKey(id)) unique[id] = u;
            }
            List<String> imgs = unique.values.toList()..shuffle();
            if (imgs.isNotEmpty) {
              await FirebaseFirestore.instance.collection('stats').doc('banners').set({
                'urls': imgs.take(20).toList(),
                'ultima_actualizacion': FieldValue.serverTimestamp(),
              });
            }
          }
          await webView.dispose();
        },
      );
      await webView.run();
    } catch (e) {}
  }

  Future<void> _incrementarEstadisticasGlobales() async {
    try { await _db.saveStatsGlobales({'total_escaneos': FieldValue.increment(1)}); } catch (e) {}
  }

  void toggleFavorito(Map<String, String> oferta) async {
    final id = oferta['id'];
    if (_ofertasGuardadas.any((o) => o['id'] == id)) {
      _ofertasGuardadas.removeWhere((o) => o['id'] == id);
    } else {
      // Free limit removed temporarily
      _ofertasGuardadas.add(oferta);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritos', jsonEncode(_ofertasGuardadas));
    if (estaLogueado) _actualizarUsuarioEnFirestore();
  }

  void limpiarTodosFavoritos() async {
    _ofertasGuardadas.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favoritos');
    if (estaLogueado) _actualizarUsuarioEnFirestore();
  }

  bool esFavorito(String id) => _ofertasGuardadas.any((o) => o['id'] == id);

  void detenerEscaneo() {
    _isEscaneando = false;
    _timer?.cancel();
    _notificationsPlugin.cancel(888);
    notifyListeners();
  }

  Future<void> _actualizarNotificacionFija() async {
    if (!_isEscaneando) return;
    const details = AndroidNotificationDetails(
      'toofast_status_persistent_v3', 'Estado del Radar (Activo)',
      importance: Importance.max, priority: Priority.high,
      ongoing: true, autoCancel: false, silent: true, onlyAlertOnce: true,
      category: AndroidNotificationCategory.service, icon: '@mipmap/ic_launcher',
    );
    await _notificationsPlugin.show(888, '🛰️ Radar TooFast Activo', 'Escaneando ${_subcategoria.isNotEmpty ? _subcategoria : _categoria}...', const NotificationDetails(android: details));
  }

  Future<void> _dispararNotificacion(int count) async {
    if (!_notificacionesHabilitadas) return;
    const details = AndroidNotificationDetails('toofast_radar_channel', 'Alertas de Radar', importance: Importance.max, priority: Priority.high);
    await _notificationsPlugin.show(0, '⚡ ¡Filtro Activado!', 'Toofast cazó $count oferta(s).', const NotificationDetails(android: details));
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); 
    super.dispose(); 
  }

  int _convertirFrecuenciaASegundos(String v) {
    if (v == '1hora') return 3600;
    if (v == '30min') return 1800;
    if (v == '15min') return 900;
    if (v == '10min') return 600;
    return 300;
  }
}

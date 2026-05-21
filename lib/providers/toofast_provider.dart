import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ToofastProvider extends ChangeNotifier {
  bool _isEscaneando = false;
  bool get isEscaneando => _isEscaneando;

  // 🔑 Variables de Autenticación
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _usuario;
  GoogleSignInAccount? get usuario => _usuario;
  bool get estaLogueado => _usuario != null;

  String? _fotoPerfilUrl;
  String? get fotoPerfilUrl => _fotoPerfilUrl ?? _usuario?.photoUrl;

  bool _estaCargandoFoto = false;
  bool get estaCargandoFoto => _estaCargandoFoto;

  // 💎 Estado de Suscripción
  bool _esPremium = false; 
  bool get esPremium => _esPremium;
  DateTime? _vencimientoPremium;
  DateTime? get vencimientoPremium => _vencimientoPremium;
  String? _planActual;
  String? get planActual => _planActual;

  bool _soyAdminEnFirestore = false;
  bool get esAdmin => _usuario?.email == 'krvillamil1990@gmail.com' || _soyAdminEnFirestore;

  int _cantidadEscaneos = 0;
  int get cantidadEscaneos => _cantidadEscaneos;

  Stream<QuerySnapshot> get streamUsuarios => 
      FirebaseFirestore.instance.collection('usuarios').snapshots();

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

  List<String> _categoriasVisibles = [
    'vehiculos',
    'inmobiliaria',
    'tecnologia',
    'electrodomesticos',
    'ropa-y-accesorios',
    'familia',
    'general',
    'hogar'
  ];
  List<String> get categoriasVisibles => _categoriasVisibles;

  void toggleVisibilidadCategoria(String slug) async {
    if (_categoriasVisibles.contains(slug)) {
      if (_categoriasVisibles.length > 1) {
        _categoriasVisibles.remove(slug);
        
        // 🚨 CRÍTICO: Si quitamos la categoría que está seleccionada actualmente,
        // debemos cambiarla a una que sí esté visible para evitar el crash del Dropdown.
        if (_categoria == slug) {
          _categoria = _categoriasVisibles.first;
        }
      }
    } else {
      _categoriasVisibles.add(slug);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categoriasVisibles', _categoriasVisibles);
    await prefs.setString('categoria', _categoria);
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
    if (seleccionar) {
      _categoriasVisibles = List.from(listaCategorias);
    } else {
      // Dejamos al menos una para evitar errores
      _categoriasVisibles = [listaCategorias.first];
      _categoria = listaCategorias.first;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categoriasVisibles', _categoriasVisibles);
    await prefs.setString('categoria', _categoria);
  }

  ToofastProvider() {
    _cargarDatosLocales();
    _inicializarNotificaciones();
    _revisarLoginSilencioso();
  }

  Future<void> _revisarLoginSilencioso() async {
    _usuario = await _googleSignIn.signInSilently();
    if (_usuario != null) {
      await _sincronizarUsuarioDesdeFirestore();
    }
    notifyListeners();
  }

  Future<void> _sincronizarUsuarioDesdeFirestore() async {
    if (_usuario == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_usuario!.id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        
        // 1. Cargar Foto
        _fotoPerfilUrl = data['foto'];
        
        // 2. Cargar Estado Premium desde la nube
        _esPremium = data['esPremium'] == true;
        _planActual = data['planActual'];
        _soyAdminEnFirestore = data['esAdmin'] == true;
        
        print("📡 Firestore: Usuario es Premium: $_esPremium | Plan: $_planActual");

        String? vencimientoStr = data['vencimientoPremium'];
        if (vencimientoStr != null && vencimientoStr.isNotEmpty) {
          _vencimientoPremium = DateTime.parse(vencimientoStr);
          
          // Verificar expiración (si no es admin)
          if (_usuario!.email != 'krvillamil1990@gmail.com' && 
              _vencimientoPremium!.isBefore(DateTime.now())) {
            _esPremium = false;
            print("⏰ Membresía expirada según Firestore");
          } else {
            _verificarExpiracionProxima();
          }
        }
        
        // 3. Persistir localmente para velocidad
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('vencimientoPremium', _vencimientoPremium?.toIso8601String() ?? '');
        await prefs.setString('planActual', _planActual ?? '');
      }

      // Siempre aplicar lógica de Admin por si acaso
      if (_usuario!.email == 'krvillamil1990@gmail.com') {
        await activarPlanPremium('6 Meses + 20 Días');
      } else if (_usuario!.email == 'valeriajuegos091022@gmail.com' || _usuario!.email == 'wowdiego94@gmail.com') {
        await activarPlanPremium('7 Días');
      }

      // Actualizar última conexión sin sobrescribir el estado Premium recién obtenido
      await _actualizarUsuarioEnFirestore();
      
    } catch (e) {
      print("Error sincronizando desde Firestore: $e");
    }
  }

  Future<void> _actualizarUsuarioEnFirestore() async {
    if (_usuario == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_usuario!.id).set({
        'id': _usuario!.id,
        'nombre': _usuario!.displayName,
        'email': _usuario!.email,
        'foto': _usuario!.photoUrl,
        'esPremium': _esPremium,
        'vencimientoPremium': _vencimientoPremium?.toIso8601String(),
        'planActual': _planActual,
        'esAdmin': esAdmin, // Mantiene el estatus de admin si lo tiene
        'ultima_conexion': FieldValue.serverTimestamp(),
        // Usamos set con merge para no sobrescribir fecha_registro si ya existe
      }, SetOptions(merge: true));
      
      // Si es la primera vez (podemos verificarlo o simplemente intentar añadir fecha_registro si falta)
      // Pero Firestore no tiene "set if not exists" para campos específicos fácilmente con merge
      // Una opción es usar un servidor timestamp para la creación solo si el documento es nuevo.
      // Por simplicidad, el merge:true y ultima_conexion es suficiente para rastrear actividad.
    } catch (e) {
      print("Error guardando usuario en Firestore: $e");
    }
  }

  Future<void> iniciarSesionGoogle() async {
    try {
      _usuario = await _googleSignIn.signIn();
      
      if (_usuario != null) {
        // Sincronizamos PRIMERO desde la nube para no sobrescribir con 'false'
        await _sincronizarUsuarioDesdeFirestore();
        
        notifyListeners(); // Actualizamos UI de inmediato

        // Guardamos fecha de registro solo si no existe (Firestore merge maneja esto bien)
        FirebaseFirestore.instance.collection('usuarios').doc(_usuario!.id).set({
          'fecha_registro': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      print("🔴 ERROR DETALLADO DE GOOGLE: $error");
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    
    // 🧹 Resetear todo el estado del usuario
    _usuario = null;
    _fotoPerfilUrl = null;
    _esPremium = false;
    _vencimientoPremium = null;
    _planActual = null;
    
    // 🧹 Limpiar persistencia local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vencimientoPremium');
    await prefs.remove('planActual');
    // Nota: mantenemos favoritos y filtros si queremos que persistan localmente, 
    // pero las reglas Freemium se aplicarán al ser _esPremium = false.

    notifyListeners();
  }

  Future<void> cambiarFotoPerfil() async {
    if (_usuario == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 300); // 📸 Más pequeña para Firestore

    if (image != null) {
      _estaCargandoFoto = true;
      notifyListeners();

      try {
        // 1. Convertir imagen a Base64 (Texto)
        final bytes = await image.readAsBytes();
        String base64Image = base64Encode(bytes);
        String dataUrl = "data:image/jpeg;base64,$base64Image";

        // 2. Guardar directamente en Firestore
        await FirebaseFirestore.instance.collection('usuarios').doc(_usuario!.id).set({
          'foto': dataUrl,
        }, SetOptions(merge: true));

        _fotoPerfilUrl = dataUrl;
        print("✅ Foto guardada en Firestore como Base64");
      } catch (e) {
        print("❌ Error al convertir/guardar foto: $e");
      } finally {
        _estaCargandoFoto = false;
        notifyListeners();
      }
    }
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
    _notificacionesHabilitadas = prefs.getBool('notificacionesHabilitadas') ?? true;
    _planActual = prefs.getString('planActual');
    _cantidadEscaneos = prefs.getInt('cantidadEscaneos') ?? 0;
    
    final savedCats = prefs.getStringList('categoriasVisibles');
    if (savedCats != null) {
      _categoriasVisibles = savedCats;
    }

    // 🚨 SEGURIDAD: Asegurar que la categoría seleccionada esté en las visibles
    if (!_categoriasVisibles.contains(_categoria)) {
      _categoria = _categoriasVisibles.first;
    }

    _verificarExpiracionProxima();
    
    final vencimientoStr = prefs.getString('vencimientoPremium');
    if (vencimientoStr != null) {
      _vencimientoPremium = DateTime.parse(vencimientoStr);
      // Verificar si ya expiró
      if (_vencimientoPremium!.isBefore(DateTime.now()) && _usuario?.email != 'krvillamil1990@gmail.com') {
        _esPremium = false;
      } else if (_vencimientoPremium!.isAfter(DateTime.now()) || _usuario?.email == 'krvillamil1990@gmail.com') {
        _esPremium = true;
      }
    }

    final String? favoritosJson = prefs.getString('favoritos');
    if (favoritosJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritosJson);
      _ofertasGuardadas = decoded.map((item) => Map<String, String>.from(item)).toList();
    }
    notifyListeners();
  }

  void _verificarExpiracionProxima() async {
    if (!_esPremium || _vencimientoPremium == null) return;

    final diff = _vencimientoPremium!.difference(DateTime.now());
    
    // Si quedan menos de 24 horas y más de 0
    if (diff.inHours >= 0 && diff.inHours <= 24) {
      final prefs = await SharedPreferences.getInstance();
      final lastWarning = prefs.getString('ultimoAvisoExpiracion');
      final hoy = DateTime.now().toIso8601String().split('T')[0];

      // Solo avisar una vez al día para no molestar
      if (lastWarning != hoy) {
        _notificarExpiracion(diff.inHours);
        await prefs.setString('ultimoAvisoExpiracion', hoy);
      }
    }
  }

  Future<void> _notificarExpiracion(int horas) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'toofast_expiration_channel', 'Aviso de Expiración',
      channelDescription: 'Notificaciones sobre el estado de tu membresía',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    String msg = horas > 0 
      ? 'Tu membresía Premium expira en aproximadamente $horas horas. ¡Renuévala para no perder tus beneficios!'
      : 'Tu membresía Premium está a punto de expirar. ¡Renuévala ahora!';

    await _notificationsPlugin.show(
      999, // ID único para avisos de expiración
      '💎 Membresía por vencer', 
      msg, 
      platformChannelSpecifics
    );
  }

  void cambiarCategoria(String nuevaCategoria) {
    _categoria = nuevaCategoria;
    notifyListeners();
  }

  void setNotificaciones(bool valor) async {
    _notificacionesHabilitadas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacionesHabilitadas', valor);
  }

  Future<void> activarPlanPremium(String plan) async {
    _esPremium = true;
    _planActual = plan;
    DateTime ahora = DateTime.now();
    
    switch (plan) {
      case '7 Días':
        _vencimientoPremium = ahora.add(const Duration(days: 7));
        break;
      case '1 Mes + 10 Días':
        _vencimientoPremium = ahora.add(const Duration(days: 40));
        break;
      case '6 Meses + 20 Días':
        _vencimientoPremium = ahora.add(const Duration(days: 200));
        break;
      case 'Admin': // Para tu cuenta especial
        _vencimientoPremium = ahora.add(const Duration(days: 3650)); // 10 años
        _planActual = '6 Meses + 20 Días'; // Tratar admin como plan máximo
        break;
    }

    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vencimientoPremium', _vencimientoPremium!.toIso8601String());
    await prefs.setString('planActual', _planActual!);
    await _actualizarUsuarioEnFirestore();
  }

  Future<void> adminActivarPremium(String userId, String plan) async {
    if (!esAdmin) return;

    DateTime ahora = DateTime.now();
    DateTime vencimiento;
    
    switch (plan) {
      case '7 Días':
        vencimiento = ahora.add(const Duration(days: 7));
        break;
      case '1 Mes + 10 Días':
        vencimiento = ahora.add(const Duration(days: 40));
        break;
      case '6 Meses + 20 Días':
        vencimiento = ahora.add(const Duration(days: 200));
        break;
      default:
        vencimiento = ahora.add(const Duration(days: 7));
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
      'esPremium': true,
      'planActual': plan,
      'vencimientoPremium': vencimiento.toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> adminDesactivarPremium(String userId) async {
    if (!esAdmin) return;
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
      'esPremium': false,
      'planActual': null,
      'vencimientoPremium': null,
    }, SetOptions(merge: true));
  }

  Future<void> adminAsignarAdmin(String userId, bool setAdmin) async {
    if (!esAdmin) return;
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
      'esAdmin': setAdmin,
    }, SetOptions(merge: true));
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

    // 🔒 REGLAS FREEMIUM: Forzar valores si no es premium
    if (!_esPremium) {
      _precioDesde = '';
      _precioHasta = '';
      _palabraClave = '';
      _frecuencia = '1hora';
    } else {
      _precioDesde = desde;
      _precioHasta = hasta;
      _palabraClave = palabraClave.trim();
      _frecuencia = frecuenciaSeleccionada;
    }

    _categoria = categoria;

    _cantidadEscaneos++;
    _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cantidadEscaneos', _cantidadEscaneos);
    await prefs.setString('precioDesde', _precioDesde);
    await prefs.setString('precioHasta', _precioHasta);
    await prefs.setString('categoria', _categoria);
    await prefs.setString('palabraClave', _palabraClave);

    _idsNotificados.clear();
    _ejecutarScrapingReal();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_proximaRevisionEnSegundos > 0) {
        _proximaRevisionEnSegundos--;
        notifyListeners();
      } else {
        _cantidadEscaneos++;
        _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);
        _ejecutarScrapingReal();
        _guardarContadorEscaneos();
      }
    });
  }

  Future<void> _guardarContadorEscaneos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cantidadEscaneos', _cantidadEscaneos);
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
    if (!_notificacionesHabilitadas) return;

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
    if (existe) { 
      _ofertasGuardadas.removeWhere((item) => item['id'] == oferta['id']); 
    } else { 
      // 🔒 Límite de 1 favorito para usuarios FREE
      if (!_esPremium && _ofertasGuardadas.isNotEmpty) {
        return;
      }
      _ofertasGuardadas.add(oferta); 
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritos', jsonEncode(_ofertasGuardadas));
  }

  void limpiarTodosFavoritos() async {
    _ofertasGuardadas.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favoritos');
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
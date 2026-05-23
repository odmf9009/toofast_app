import 'dart:async';
import 'dart:convert';
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
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ToofastProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isEscaneando = false;
  bool get isEscaneando => _isEscaneando;
  
  bool _appEnPrimerPlano = true; // 🔋 Para ahorro de energía

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
  
  bool _pruebaUsada = false;
  bool get pruebaUsada => _pruebaUsada;

  int _totalUsuarios = 0;
  int get totalUsuarios => _totalUsuarios;
  int _totalEscaneosGlobales = 0;
  int get totalEscaneosGlobales => _totalEscaneosGlobales;
  
  List<String> _bannerUrls = [];
  List<String> get bannerUrls => _bannerUrls;

  Map<String, List<Map<String, String>>> _subcategorias = {
    'vehiculos': [
      {'name': 'Motos Eléctricas y Triciclos', 'slug': 'vehiculos-motos-electricas-y-triciclos'},
      {'name': 'Motos de Combustión', 'slug': 'vehiculos-motos-de-combustion'},
      {'name': 'Repuestos y Accesorios de Motos', 'slug': 'vehiculos-repuestos-y-accesorios-de-motos'},
      {'name': 'Carros', 'slug': 'vehiculos-carros'},
      {'name': 'Repuestos y Accesorios de Carros', 'slug': 'vehiculos-repuestos-y-accesorios-de-carros'},
      {'name': 'Bicicletas', 'slug': 'vehiculos-bicicletas'},
      {'name': 'Alquiler de Carros', 'slug': 'vehiculos-alquiler-de-carros'},
      {'name': 'Otros - Vehículos', 'slug': 'vehiculos-otros-vehiculos'},
    ],
    'inmobiliaria': [
      {'name': 'Casas', 'slug': 'inmobiliaria-casas'},
      {'name': 'Alquiler a Cubanos', 'slug': 'inmobiliaria-alquiler-a-cubanos'},
      {'name': 'Alquiler a Extranjeros', 'slug': 'inmobiliaria-alquiler-a-extranjeros'},
      {'name': 'Alquiler Vacacional', 'slug': 'inmobiliaria-alquiler-vacacional'},
      {'name': 'Permutas', 'slug': 'inmobiliaria-permutas'},
      {'name': 'Otros - Inmobiliaria', 'slug': 'inmobiliaria-otros-inmobiliaria'},
    ],
    'tecnologia': [
      {'name': 'Celulares y Accesorios', 'slug': 'tecnologia-celulares-y-accesorios'},
      {'name': 'Televisores e Imagen', 'slug': 'tecnologia-televisores-e-imagen'},
      {'name': 'Computadoras y Tablets', 'slug': 'tecnologia-computadoras-y-tablets'},
      {'name': 'Accesorios de Computadoras', 'slug': 'tecnologia-accesorios-de-computadoras'},
      {'name': 'Consolas y Videojuegos', 'slug': 'tecnologia-consolas-y-videojuegos'},
      {'name': 'Audífonos, Bocinas y Sonido', 'slug': 'tecnologia-audifonos-bocinas-y-sonido'},
      {'name': 'Cámaras y Fotografía', 'slug': 'tecnologia-camaras-y-fotografia'},
      {'name': 'Otros - Tecnología', 'slug': 'tecnologia-otros-tecnologia'},
    ],
    'ropa-y-accesorios': [
      {'name': 'Ropa de Mujer', 'slug': 'ropa-y-accesorios-ropa-de-mujer'},
      {'name': 'Zapatos de Mujer', 'slug': 'ropa-y-accesorios-zapatos-de-mujer'},
      {'name': 'Ropa de Hombre', 'slug': 'ropa-y-accesorios-ropa-de-hombre'},
      {'name': 'Zapatos de Hombre', 'slug': 'ropa-y-accesorios-zapatos-de-hombre'},
      {'name': 'Relojes, Joyas y Accesorios', 'slug': 'ropa-y-accesorios-relojes-joyas-y-accesorios'},
      {'name': 'Belleza, Maquillaje y Perfumes', 'slug': 'ropa-y-accesorios-belleza-maquillaje-y-perfumes'},
      {'name': 'Otros - Ropa y Accesorios', 'slug': 'ropa-y-accesorios-otros-ropa-y-accesorios'},
    ],
    'servicios': [
      {'name': 'Construcción y Mantenimiento', 'slug': 'servicios-construccion-y-mantenimiento'},
      {'name': 'Catering y Comida a Domicilio', 'slug': 'servicios-catering-y-comida-a-domicilio'},
      {'name': 'Belleza, Salud y Cuidado Personal', 'slug': 'servicios-belleza-salud-y-cuidado-personal'},
      {'name': 'Talleres y Reparaciones', 'slug': 'servicios-talleres-y-reparaciones'},
      {'name': 'Eventos y Entretenimiento', 'slug': 'servicios-eventos-y-entretenimiento'},
      {'name': 'Limpieza y Cuidado', 'slug': 'servicios-limpieza-y-cuidado'},
      {'name': 'Clases y Cursos', 'slug': 'servicios-clases-y-cursos'},
      {'name': 'Informática, Creatividad y Marketing', 'slug': 'servicios-informatica-creatividad-y-marketing'},
      {'name': 'Transporte y Logística', 'slug': 'servicios-transporte-y-logistica'},
    ],
    'electrodomesticos': [
      {'name': 'Refrigeradores y Neveras', 'slug': 'electrodomesticos-refrigeradores-y-neveras'},
      {'name': 'Lavadoras y Secadoras', 'slug': 'electrodomesticos-lavadoras-y-secadoras'},
      {'name': 'Cocinas y Hornos', 'slug': 'electrodomesticos-cocinas-y-hornos'},
      {'name': 'Ventiladores', 'slug': 'electrodomesticos-ventiladores'},
      {'name': 'Aire Acondicionado', 'slug': 'electrodomesticos-aire-acondicionado'},
      {'name': 'Pequeño Electrodoméstico', 'slug': 'electrodomesticos-pequeno-electrodomestico'},
      {'name': 'Otros - Electrodomésticos', 'slug': 'electrodomesticos-otros-electrodomesticos'},
    ],
    'empleos': [
      {'name': 'Ofertas de Empleo', 'slug': 'empleos-ofertas-de-empleo'},
      {'name': 'Busco Empleo', 'slug': 'empleos-busco-empleo'},
    ],
    'hogar': [
      {'name': 'Muebles', 'slug': 'hogar-muebles'},
      {'name': 'Arte, Antigüedades y Colección', 'slug': 'hogar-arte-antiguedades-y-coleccion'},
      {'name': 'Plantas y Estaciones de Energía', 'slug': 'hogar-plantas-y-estaciones-de-energia'},
      {'name': 'Materiales de Construcción', 'slug': 'hogar-materiales-de-construccion'},
      {'name': 'Ferretería y Herramientas', 'slug': 'hogar-ferreteria-y-herramientas'},
      {'name': 'Artículos del Hogar', 'slug': 'hogar-articulos-del-hogar'},
      {'name': 'Otros - Hogar', 'slug': 'hogar-otros-hogar'},
    ]
  };
  Map<String, List<Map<String, String>>> get subcategorias => _subcategorias;

  Map<String, String> _nombresCategorias = {
    'vehiculos': 'Vehículos',
    'inmobiliaria': 'Inmobiliaria',
    'tecnologia': 'Tecnología',
    'ropa-y-accesorios': 'Ropa y Accesorios',
    'servicios': 'Servicios',
    'electrodomesticos': 'Electrodomésticos',
    'empleos': 'Empleos',
    'hogar': 'Hogar',
  };
  Map<String, String> get nombresCategorias => _nombresCategorias;

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
    'ropa-y-accesorios',
    'servicios',
    'electrodomesticos',
    'empleos',
    'hogar'
  ];

  List<String> _categoriasVisibles = [
    'vehiculos',
    'inmobiliaria',
    'tecnologia',
    'ropa-y-accesorios',
    'servicios',
    'electrodomesticos',
    'empleos',
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
    WidgetsBinding.instance.addObserver(this); // 🔋 Registrar observador de energía
    _cargarDatosLocales();
    _inicializarNotificaciones();
    _revisarLoginSilencioso();
    _escucharEstadisticasGlobales();
    // Plan B: El admin actualiza los banners globales desde su dispositivo real
    Timer(const Duration(seconds: 5), () {
      if (esAdmin) {
        _actualizarBannersGlobalesDesdeApp();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appEnPrimerPlano = (state == AppLifecycleState.resumed);
    print("🔋 Estado de energía: ${_appEnPrimerPlano ? 'Alto Rendimiento' : 'Modo Ahorro (Background)'}");
    
    // Si volvemos al primer plano y el timer estaba pausado, podemos forzar un refresh si es necesario
    if (_appEnPrimerPlano && _isEscaneando) {
      // Opcional: Ejecutar un escaneo inmediato al volver
    }
  }

  void _escucharEstadisticasGlobales() {
    // 1. Escuchar total de usuarios
    FirebaseFirestore.instance.collection('usuarios').snapshots().listen((snapshot) {
      _totalUsuarios = snapshot.docs.length;
      notifyListeners();
    });

    // 2. Escuchar escaneos globales (usando un documento de stats centralizado)
    FirebaseFirestore.instance.collection('stats').doc('globales').snapshots().listen((doc) {
      if (doc.exists) {
        _totalEscaneosGlobales = doc.data()?['total_escaneos'] ?? 0;
        notifyListeners();
      }
    });

    // 3. Escuchar URLs de banners de Revolico
    FirebaseFirestore.instance.collection('stats').doc('banners').snapshots().listen((doc) {
      if (doc.exists) {
        final List<dynamic> data = doc.data()?['urls'] ?? [];
        _bannerUrls = data.cast<String>();
        notifyListeners();
      }
    });

    // 4. Escuchar subcategorías
    FirebaseFirestore.instance.collection('stats').doc('categorias').snapshots().listen((doc) {
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() ?? {};
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
        _pruebaUsada = data['pruebaUsada'] == true;
        
        print("📡 Firestore: Usuario es Premium: $_esPremium | Plan: $_planActual");

        // 3. Cargar Favoritos del Usuario
        if (data['favoritos'] != null) {
          final List<dynamic> favs = data['favoritos'];
          _ofertasGuardadas = favs.map((item) => Map<String, String>.from(item)).toList();
          // Actualizar localmente también
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('favoritos', jsonEncode(_ofertasGuardadas));
        }

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
        'pruebaUsada': _pruebaUsada,
        'esAdmin': esAdmin, // Mantiene el estatus de admin si lo tiene
        'favoritos': _ofertasGuardadas, // ⭐️ Guardar favoritos vinculados al usuario
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
    _ofertasGuardadas = []; // 🧹 Limpiar favoritos al desloguearse
    
    // 🧹 Limpiar persistencia local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vencimientoPremium');
    await prefs.remove('planActual');
    await prefs.remove('favoritos'); // 🧹 Borrar favoritos locales del dispositivo

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
    _subcategoria = prefs.getString('subcategoria_seleccionada') ?? '';
    _palabraClave = prefs.getString('palabraClave') ?? ''; // Cargar palabra clave
    _notificacionesHabilitadas = prefs.getBool('notificacionesHabilitadas') ?? true;
    _autoGuardarAlertas = prefs.getBool('autoGuardarAlertas') ?? false;
    _maxAutoGuardados = prefs.getInt('maxAutoGuardados') ?? 5;
    _planActual = prefs.getString('planActual');
    _pruebaUsada = prefs.getBool('pruebaUsada') ?? false;
    _cantidadEscaneos = prefs.getInt('cantidadEscaneos') ?? 0;
    
    final savedCats = prefs.getStringList('categoriasVisibles');
    if (savedCats != null) {
      // 🛡️ FILTRO DE SEGURIDAD: Solo mantener categorías que existen actualmente en la app
      _categoriasVisibles = savedCats.where((slug) => listaCategorias.contains(slug)).toList();
      
      // Si después de filtrar queda vacía (muy raro), resetear a la lista por defecto
      if (_categoriasVisibles.isEmpty) {
        _categoriasVisibles = List.from(listaCategorias);
      }
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

    // Cargar subcategorías locales si existen
    final String? subcatsJson = prefs.getString('subcategorias');
    if (subcatsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(subcatsJson);
      _subcategorias = {};
      decoded.forEach((key, value) {
        if (value is List) {
          _subcategorias[key] = value.map((item) => Map<String, String>.from(item)).toList();
        }
      });
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

  void cambiarCategoria(String nuevaCategoria) async {
    _categoria = nuevaCategoria;
    _subcategoria = ''; // Resetear subcategoría al cambiar categoría
    _palabraClave = ''; // ✨ Limpiar palabra clave al cambiar categoría
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoria', nuevaCategoria);
    await prefs.setString('palabraClave', '');
  }

  void cambiarSubcategoria(String nuevaSub) async {
    _subcategoria = nuevaSub;
    _palabraClave = ''; // ✨ Limpiar palabra clave al cambiar subcategoría
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
    if (!_esPremium) return;
    _autoGuardarAlertas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoGuardarAlertas', valor);
  }

  void setMaxAutoGuardados(int valor) async {
    if (!_esPremium) return;
    if (valor < 1) valor = 1;
    if (valor > 10) valor = 10;
    _maxAutoGuardados = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxAutoGuardados', valor);
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

  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // ID único del hardware en Android
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // ID único del fabricante en iOS
    }
    return null;
  }

  Future<int> activarPruebaGratuita() async {
    // Retorna: 1 (Éxito), 0 (Ya usada por usuario), -1 (Ya usada por este dispositivo), -2 (Error)
    if (_usuario == null) return -2;
    if (_pruebaUsada || _esPremium) return 0;

    try {
      final String? deviceId = await _getDeviceId();
      if (deviceId == null) return -2;

      // 1. Verificar si este dispositivo ya activó una prueba (con cualquier cuenta)
      final deviceDoc = await FirebaseFirestore.instance.collection('dispositivos_pruebas').doc(deviceId).get();
      
      if (deviceDoc.exists) {
        print("🚫 Intento de fraude: Este dispositivo ($deviceId) ya consumió su prueba gratuita.");
        return -1; 
      }

      // 2. Si es apto, proceder con la activación
      _esPremium = true;
      _pruebaUsada = true;
      _planActual = 'Prueba 3 Días';
      _vencimientoPremium = DateTime.now().add(const Duration(days: 3));

      // 3. Registrar en Firestore el dispositivo para bloquearlo a futuro
      await FirebaseFirestore.instance.collection('dispositivos_pruebas').doc(deviceId).set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_id': _usuario!.id,
        'email': _usuario!.email,
      });

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vencimientoPremium', _vencimientoPremium!.toIso8601String());
      await prefs.setString('planActual', _planActual!);
      await prefs.setBool('pruebaUsada', true);
      
      await _actualizarUsuarioEnFirestore();
      return 1;
    } catch (e) {
      print("Error activando prueba: $e");
      return -2;
    }
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

    // 🔒 REGLAS FREEMIUM: Ajustar valores según nivel de suscripción
    if (!_esPremium) {
      _precioDesde = desde;
      _precioHasta = hasta;
      
      // Permitir solo una palabra para usuarios FREE
      String keyword = palabraClave.trim();
      if (keyword.contains(' ')) {
        _palabraClave = keyword.split(' ')[0];
      } else {
        _palabraClave = keyword;
      }

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
    
    // Incrementar estadísticas globales en Firestore
    _incrementarEstadisticasGlobales();

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cantidadEscaneos', _cantidadEscaneos);
    await prefs.setString('precioDesde', _precioDesde);
    await prefs.setString('precioHasta', _precioHasta);
    await prefs.setString('categoria', _categoria);
    await prefs.setString('palabraClave', _palabraClave);

    _idsNotificados.clear();
    _ejecutarScrapingReal();
    _actualizarNotificacionFija(); // 🛰️ Mostrar notificación fija al iniciar

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 🛰️ Asegurar que la notificación se mantenga (algunos Android la ocultan si no se refresca)
      if (_cantidadEscaneos % 30 == 0 && _proximaRevisionEnSegundos == 5) {
         _actualizarNotificacionFija();
      }

      if (_proximaRevisionEnSegundos > 0) {
        // ⚡️ OPTIMIZACIÓN: Si la app está en background, el contador baja igual para disparar la notificación,
        // pero podemos ahorrar recursos de UI al no notificar a los listeners si no es necesario.
        _proximaRevisionEnSegundos--;
        if (_appEnPrimerPlano) notifyListeners();
      } else {
        _cantidadEscaneos++;
        _proximaRevisionEnSegundos = _convertirFrecuenciaASegundos(_frecuencia);
        _ejecutarScrapingReal();
        _guardarContadorEscaneos();
      }
    });
  }

  Future<void> _incrementarEstadisticasGlobales() async {
    try {
      await FirebaseFirestore.instance.collection('stats').doc('globales').set({
        'total_escaneos': FieldValue.increment(1),
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error actualizando estadísticas globales: $e");
    }
  }

  // Plan B: Scraping de banners desde el dispositivo real (IP Residencial) para evitar 403
  Future<void> _actualizarBannersGlobalesDesdeApp() async {
    try {
      // 1. Verificar cuándo fue la última actualización global
      final doc = await FirebaseFirestore.instance.collection('stats').doc('banners').get();
      if (doc.exists) {
        final Timestamp? ultimaVez = doc.data()?['ultima_actualizacion'];
        if (ultimaVez != null) {
          final diferencia = DateTime.now().difference(ultimaVez.toDate());
          // Si han pasado menos de 24 horas, no hacemos nada
          if (diferencia.inHours < 24) {
            print("⏳ [Admin] Banners actualizados hace ${diferencia.inHours}h. Próxima actualización en ${24 - diferencia.inHours}h.");
            return;
          }
        }
      }

      print("🛰️ [Admin] Han pasado 24h. Iniciando actualización de banners globales...");

      late HeadlessInAppWebView headlessWebView;
      bool yaProcesado = false;

      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://www.revolico.com/")),
        onLoadStop: (controller, url) async {
          if (yaProcesado) return;
          yaProcesado = true;

          final String? html = await controller.getHtml();
          if (html != null) {
            // 1. Extraer Banners
            final regex = RegExp(r'https://pic\.revolico\.com/pics/[a-zA-Z0-9._-]+\.jpg');
            final matches = regex.allMatches(html);
            
            Map<String, String> uniqueAds = {};
            for (var m in matches) {
              String url = m.group(0)!;
              String fileName = url.split('/').last;
              String id = fileName.split('_').first;
              if (!uniqueAds.containsKey(id)) uniqueAds[id] = url;
            }

            List<String> images = uniqueAds.values.toList();
            images.shuffle();

            if (images.isNotEmpty) {
              final finalUrls = images.take(20).toList();
              await FirebaseFirestore.instance.collection('stats').doc('banners').set({
                'urls': finalUrls,
                'ultima_actualizacion': FieldValue.serverTimestamp(),
                'actualizado_por': _usuario?.email ?? 'admin_device'
              });
            }

            // 2. Extraer Categorías y Subcategorías (Deep Scan)
            if (html.contains('id="__NEXT_DATA__"')) {
              final String jsonString = html.split('id="__NEXT_DATA__"')[1].split('>')[1].split('</script>')[0].trim();
              final Map<String, dynamic> data = jsonDecode(jsonString);
              
              // Intentar obtener de Props (Página Home)
              List<dynamic> categoriesRaw = data['props']?['pageProps']?['categories'] ?? [];
              
              // Si está vacío, intentar obtener del Apollo State (Mucho más fiable)
              if (categoriesRaw.isEmpty) {
                final apollo = data['props']?['pageProps']?['__APOLLO_STATE__'] ?? {};
                apollo.forEach((key, value) {
                  if (key.startsWith('Category:')) {
                    // Aquí podemos reconstruir la jerarquía si es necesario, 
                    // pero usualmente los props son suficientes en el Home.
                  }
                });
              }

              Map<String, List<Map<String, String>>> allSubcats = {};
              Map<String, String> names = {};

              for (var cat in categoriesRaw) {
                String catSlug = cat['slug'] ?? '';
                String catName = cat['name'] ?? '';
                if (catSlug.isEmpty) continue;

                names[catSlug] = catName;
                List<dynamic> children = cat['children'] ?? [];
                if (children.isNotEmpty) {
                  allSubcats[catSlug] = children.map((child) {
                    String childSlug = child['slug'].toString();
                    // 🛡️ REGLA CRÍTICA: Asegurar que el slug del hijo tenga el prefijo del padre
                    // Si childSlug es 'celulares' y catSlug es 'tecnologia', el slug final debe ser 'tecnologia-celulares'
                    if (!childSlug.startsWith(catSlug)) {
                      childSlug = '$catSlug-$childSlug';
                    }
                    return {
                      'name': child['name'].toString(),
                      'slug': childSlug,
                    };
                  }).toList();
                }
              }

              if (allSubcats.isNotEmpty) {
                await FirebaseFirestore.instance.collection('stats').doc('categorias').set({
                  ...allSubcats,
                  'ultima_actualizacion': FieldValue.serverTimestamp(),
                });
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('subcategorias', jsonEncode(allSubcats));
                _subcategorias = allSubcats;
                _nombresCategorias = names;
                print("✅ [Admin] Subcategorías actualizadas: ${allSubcats.length} categorías con hijos.");
                notifyListeners();
              }
            }
          }
          await headlessWebView.dispose();
        },
      );

      await headlessWebView.run();
    } catch (e) {
      print("❌ Error en actualización de banners: $e");
    }
  }

  Future<void> _guardarContadorEscaneos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cantidadEscaneos', _cantidadEscaneos);
    _incrementarEstadisticasGlobales();
  }

  Future<void> _ejecutarScrapingReal() async {
    List<Map<String, String>> resultadosAcumulados = [];
    List<Map<String, String>> nuevosParaNotificar = [];
    // 📄 Siempre permitimos hasta 5 páginas para asegurar que llegamos a la meta de anuncios orgánicos
    int paginasMax = 5;
    int metaHits = _palabraClave.isNotEmpty ? 10 : 20; // 🎯 Meta: 10 para keyword, 20 para normal.

    print("🚀 [Radar] Iniciando búsqueda exhaustiva ($paginasMax páginas max)...");

    for (int i = 1; i <= paginasMax; i++) {
      if (!_isEscaneando) break;
      if (resultadosAcumulados.length >= metaHits) break;

      print("📄 Escaneando página $i...");
      final results = await _obtenerResultadosDePagina(i);
      
      for (var oferta in results) {
        if (resultadosAcumulados.length >= metaHits) break;
        
        // Evitar duplicados en la misma tanda
        if (!resultadosAcumulados.any((x) => x['id'] == oferta['id'])) {
          resultadosAcumulados.add(oferta);
          if (!_idsNotificados.contains(oferta['id'])) {
            nuevosParaNotificar.add(oferta);
          }
        }
      }
    }

    if (resultadosAcumulados.isNotEmpty) {
      _ofertasEncontradas = resultadosAcumulados;
      if (nuevosParaNotificar.isNotEmpty && _isEscaneando) {
        _dispararNotificacion(nuevosParaNotificar.length);
        
        // 💎 Lógica Premium: Auto-guardar
        if (_esPremium && _autoGuardarAlertas) {
          bool huboCambios = false;
          int guardadosEnEsteCiclo = 0;
          for (var chollo in nuevosParaNotificar) {
            if (guardadosEnEsteCiclo >= _maxAutoGuardados) break;
            if (!_ofertasGuardadas.any((fav) => fav['id'] == chollo['id'])) {
              _ofertasGuardadas.add(chollo);
              guardadosEnEsteCiclo++;
              huboCambios = true;
            }
          }
          if (huboCambios) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('favoritos', jsonEncode(_ofertasGuardadas));
            if (estaLogueado) _actualizarUsuarioEnFirestore();
          }
        }

        for (var chollo in nuevosParaNotificar) {
          _idsNotificados.add(chollo['id']!);
        }
      }
      
      // ⚡️ ACTUALIZACIÓN FINAL: Notificamos una sola vez al terminar de procesar todas las páginas
      notifyListeners();
      _enriquecerDatosEnSegundoPlano(resultadosAcumulados);
    }
  }

  Future<List<Map<String, String>>> _obtenerResultadosDePagina(int pageNum) async {
    final completer = Completer<List<Map<String, String>>>();
    String urlOficial;
    String subFinal = _subcategoria;
    
    if (subFinal.isNotEmpty && !subFinal.startsWith(_categoria)) {
      subFinal = '$_categoria-$subFinal';
    }

    if (subFinal.isNotEmpty) {
      urlOficial = 'https://www.revolico.com/search?category=$_categoria&subcategory=$subFinal&page=$pageNum';
    } else {
      urlOficial = 'https://www.revolico.com/search?category=$_categoria&page=$pageNum';
    }

    try {
      HeadlessInAppWebView? headlessWebView;
      bool yaProcesado = false;

      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(urlOficial),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
          }
        ),
        onLoadStop: (controller, url) async {
          if (yaProcesado) return;
          yaProcesado = true;

          final String? html = await controller.getHtml();
          List<Map<String, String>> resultados = [];

          if (html != null && html.contains('id="__NEXT_DATA__"')) {
            try {
              // 🧪 EXTRACCIÓN ROBUSTA DE JSON
              String jsonString = "";
              if (html.contains('id="__NEXT_DATA__"')) {
                // Intentamos primero con un separador más corto para evitar fallos por espacios
                jsonString = html.split('id="__NEXT_DATA__"')[1].split('>')[1].split('</script')[0].trim();
                
                // Limpieza extra por si quedan restos de etiquetas
                if (jsonString.contains('</script')) {
                  jsonString = jsonString.split('</script')[0].trim();
                }
              }

              if (jsonString.isEmpty) throw Exception("No se pudo extraer el JSON");

              final Map<String, dynamic> datosEstructurados = jsonDecode(jsonString);
              final Map<String, dynamic> apolloState = datosEstructurados['pageProps']?['__APOLLO_STATE__'] ?? 
                                 datosEstructurados['props']?['pageProps']?['__APOLLO_STATE__'] ?? {};

              List<dynamic> itemsParaProcesar = [];
              final Map<String, dynamic> rootQuery = Map<String, dynamic>.from(apolloState['ROOT_QUERY'] ?? {});
              
              // 🔍 Buscar la llave de búsqueda de forma robusta
              String searchKey = "";
              for (var key in rootQuery.keys) {
                if (key.toString().startsWith('search')) {
                  searchKey = key.toString();
                  break;
                }
              }

              if (searchKey.isNotEmpty) {
                itemsParaProcesar = rootQuery[searchKey]['results'] ?? [];
              }

              // Si falla la lista ordenada, buscamos manualmente
              if (itemsParaProcesar.isEmpty) {
                apolloState.forEach((key, val) {
                  if (val is Map && val.containsKey('title') && val.containsKey('price')) {
                    itemsParaProcesar.add(val);
                  }
                });
              }

              int min = int.tryParse(_precioDesde) ?? 0;
              int max = int.tryParse(_precioHasta) ?? 999999;

              for (var item in itemsParaProcesar) {
                var value = (item is Map && item.containsKey('__ref')) ? apolloState[item['__ref']] : item;
                if (value is Map && value.containsKey('price') && value.containsKey('title')) {
                  
                  // 🚫 EXCLUIR DESTACADOS: No procesar anuncios Premium o Destacados
                  bool esDestacado = value['isFeatured'] == true || value['isPremium'] == true;
                  if (esDestacado) continue;

                  String titulo = value['title']?.toString() ?? '';
                  String descripcion = value['description']?.toString() ?? '';
                  
                  // 💰 MEJORA DE PRECIO: Manejar comas y puntos correctamente (ej: 3,5 -> 3.5)
                  String priceRaw = value['price']?.toString() ?? '0';
                  // Reemplazamos coma por punto y quitamos todo lo que no sea número o punto
                  String priceClean = priceRaw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
                  double precioDouble = double.tryParse(priceClean) ?? 0;
                  int precio = precioDouble.floor();

                  if (precio < min || precio > max) continue;

                  // 🔍 MEJORA DE COINCIDENCIA: Buscar en Título y Descripción
                  if (_palabraClave.isNotEmpty) {
                    String buscado = _palabraClave.toLowerCase().trim();
                    bool matchTitulo = titulo.toLowerCase().contains(buscado);
                    bool matchDesc = descripcion.toLowerCase().contains(buscado);
                    
                    if (!matchTitulo && !matchDesc) continue;
                  }

                  String idAnuncio = value['id']?.toString() ?? "";
                  String permalink = value['permalink']?.toString() ?? '';
                  
                  resultados.add({
                    'id': idAnuncio,
                    'titulo': titulo,
                    'precio': precio.toString(),
                    'tiempo': 'Reciente',
                    'ubicacion': 'Cuba',
                    'enlace': "https://www.revolico.com${permalink.startsWith('/') ? '' : '/'}$permalink",
                    'imagen': '',
                    'detalles': descripcion,
                  });
                }
              }
            } catch (e) { print("Error parseando página $pageNum: $e"); }
          }
          completer.complete(resultados);
          await headlessWebView?.dispose();
        },
      );
      await headlessWebView.run();
    } catch (e) {
      print("Error en scrap de página $pageNum: $e");
      if (!completer.isCompleted) completer.complete([]);
    }
    return completer.future;
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

          // E. WhatsApp (Extraer número de wa.me)
          // Patrón: https://wa.me/5350237290
          RegExp regWA = RegExp(r'https://wa\.me/(\d+)');
          var matchWA = regWA.firstMatch(html);
          if (matchWA != null) {
            ofertas[i]['whatsapp'] = matchWA.group(1) ?? "";
          } else {
            // Intento alternativo por si el número está en el texto pero no en el href
            RegExp regPhoneText = RegExp(r'\+53\s?\d\s?\d+');
            var matchPhoneText = regPhoneText.firstMatch(html);
            if (matchPhoneText != null) {
              ofertas[i]['whatsapp'] = matchPhoneText.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
            }
          }

          // F. Teléfono (Extraer número de tel:)
          // Patrón: tel:+5354840756
          RegExp regTel = RegExp(r'href="tel:(\+?\d+)"');
          var matchTel = regTel.firstMatch(html);
          if (matchTel != null) {
            ofertas[i]['telefono'] = matchTel.group(1) ?? "";
          }
          
          print("✅ [OK] ${ofertas[i]['titulo']} -> WhatsApp: ${ofertas[i]['whatsapp'] ?? 'N/A'}, Tel: ${ofertas[i]['telefono'] ?? 'N/A'}");
        }
      } catch (e) {
        print("Error enriqueciendo anuncio ${ofertas[i]['id']}: $e");
      }
      
      // ⚡️ OPTIMIZACIÓN: Solo notificamos cada 3 anuncios procesados para reducir rebuilds de la lista
      if (i % 3 == 0 || i == ofertas.length - 1) {
        notifyListeners(); 
      }
      
      await Future.delayed(const Duration(milliseconds: 300)); // Un poco más rápido pero seguro
    }
  }

  // 🤖 Función que conecta con el motor de IA Real (vía HTTPS Callable)
  Future<void> _analizarOfertaConIA(Map<String, String> oferta) async {
    try {
      print("📡 Conectando con Analista IA Gemini...");
      
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('analyzeDealWithAI');
      
      final response = await callable.call({
        'title': oferta['titulo'],
        'price': oferta['precio'],
        'description': oferta['detalles'],
      });

      if (response.data != null) {
        final data = response.data;
        oferta['ia_puntuacion'] = data['score'].toString();
        oferta['ia_analisis'] = data['analysis'].toString();
        print("🤖 IA Analizó: ${oferta['titulo']} -> ${data['score']}/10");
      }
    } catch (e) {
      print("Error en llamada real a IA: $e");
      oferta['ia_puntuacion'] = "7";
      oferta['ia_analisis'] = "Análisis técnico pendiente de conexión.";
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
    
    // ☁️ Sincronizar con la nube si el usuario está logueado
    if (estaLogueado) {
      _actualizarUsuarioEnFirestore();
    }
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
    _notificationsPlugin.cancel(888); // 🧹 Quitar notificación fija al detener
    notifyListeners();
  }

  Future<void> _actualizarNotificacionFija() async {
    if (!_isEscaneando) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'toofast_status_persistent_v3', // 🚀 Canal de alta prioridad bloqueado
      'Estado del Radar (Activo)',
      channelDescription: 'Mantiene el radar visible y bloqueado mientras escanea',
      importance: Importance.max, // Máxima importancia para evitar que se descarte
      priority: Priority.high,
      ongoing: true, // 🔒 Bloqueo de deslizamiento
      autoCancel: false,
      silent: true, // Mantiene el bloqueo pero sin hacer ruido molesto
      showWhen: true,
      onlyAlertOnce: true, // Evita que la notificación parpadee al actualizarse
      category: AndroidNotificationCategory.service,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      888, // ID fijo para el estado
      '🛰️ Radar TooFast Activo', 
      'Escaneando ${_subcategoria.isNotEmpty ? _subcategoria : _categoria}...', 
      platformChannelSpecifics
    );
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this); // 🧹 Limpiar observador
    _timer?.cancel(); 
    super.dispose(); 
  }
}

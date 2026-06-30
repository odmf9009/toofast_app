import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

const int _kForegroundNotifId = 888;
const String _kFgChannelId = 'toofast_radar_fg';
const String _kAlertChannelId = 'toofast_radar_channel';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _kFgChannelId,
      initialNotificationTitle: '🛰️ Radar Toofast',
      initialNotificationContent: 'Radar activo...',
      foregroundServiceNotificationId: _kForegroundNotifId,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notif = FlutterLocalNotificationsPlugin();
  await notif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  Timer? radarTimer;
  bool escaneando = false;
  final Set<String> idsNotificados = {};

  String categoria = 'vehiculos';
  String subcategoria = '';
  String palabraClave = '';
  String precioDesde = '';
  String precioHasta = '';
  int frecuenciaSegundos = 300;
  int countdown = 300;

  Future<void> escanear() async {
    if (escaneando) return;
    escaneando = true;
    service.invoke('estado', {'escaneando': true});

    List<Map<String, String>> acumulados = [];
    final resultados = await Future.wait(
      [1, 2, 3].map((p) => _obtenerPagina(p, categoria, subcategoria, palabraClave, precioDesde, precioHasta)),
    );
    for (var lista in resultados) {
      for (var o in lista) {
        if (!acumulados.any((x) => x['id'] == o['id'])) acumulados.add(o);
      }
    }
    if (acumulados.length < (palabraClave.isNotEmpty ? 10 : 20)) {
      for (int p = 4; p <= 5; p++) {
        final lista = await _obtenerPagina(p, categoria, subcategoria, palabraClave, precioDesde, precioHasta);
        for (var o in lista) {
          if (!acumulados.any((x) => x['id'] == o['id'])) acumulados.add(o);
        }
        if (acumulados.length >= (palabraClave.isNotEmpty ? 10 : 20)) break;
      }
    }

    final nuevos = acumulados.where((o) => !idsNotificados.contains(o['id'])).toList();
    if (nuevos.isNotEmpty) {
      for (var n in nuevos) idsNotificados.add(n['id']!);
      await notif.show(
        0,
        '⚡ ¡Nuevas ofertas!',
        'Toofast cazó ${nuevos.length} anuncio(s).',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kAlertChannelId, 'Alertas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }

    service.invoke('resultados', {
      'ofertas': acumulados.map((o) => Map<String, dynamic>.from(o)).toList(),
    });
    service.invoke('estado', {'escaneando': false});
    escaneando = false;
  }

  service.on('iniciar').listen((data) async {
    if (data == null) return;
    categoria = data['categoria'] ?? 'vehiculos';
    subcategoria = data['subcategoria'] ?? '';
    palabraClave = data['palabraClave'] ?? '';
    precioDesde = data['precioDesde'] ?? '';
    precioHasta = data['precioHasta'] ?? '';
    frecuenciaSegundos = data['frecuenciaSegundos'] ?? 300;
    countdown = frecuenciaSegundos;
    idsNotificados.clear();

    radarTimer?.cancel();
    await escanear();

    radarTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      countdown--;
      service.invoke('countdown', {'segundos': countdown});
      if (countdown <= 0) {
        countdown = frecuenciaSegundos;
        await escanear();
      }
    });
  });

  service.on('detener').listen((_) async {
    radarTimer?.cancel();
    await notif.cancel(_kForegroundNotifId);
    service.stopSelf();
  });
}

Future<List<Map<String, String>>> _obtenerPagina(
  int pageNum,
  String categoria,
  String subcategoria,
  String palabraClave,
  String precioDesde,
  String precioHasta,
) async {
  String sub = subcategoria;
  if (sub.isNotEmpty && !sub.startsWith(categoria)) sub = '$categoria-$sub';
  final url = 'https://www.revolico.com/search?category=$categoria${sub.isNotEmpty ? "&subcategory=$sub" : ""}&page=$pageNum';

  try {
    final resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'es-ES,es;q=0.8,en;q=0.5',
    }).timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200 || !resp.body.contains('__NEXT_DATA__')) return [];

    final match = RegExp(r'<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)</script>').firstMatch(resp.body);
    if (match == null) return [];

    final data = jsonDecode(match.group(1)!.trim());
    final Map<String, dynamic> apollo =
        data['props']?['pageProps']?['__APOLLO_STATE__'] ??
        data['pageProps']?['__APOLLO_STATE__'] ??
        data['__APOLLO_STATE__'] ?? {};

    List<dynamic> items = [];

    final root = Map<String, dynamic>.from(apollo['ROOT_QUERY'] ?? {});
    for (var key in root.keys) {
      if (key.toString().contains('search') || key.toString().contains('ads')) {
        final results = root[key]['results'];
        if (results is List && results.isNotEmpty) { items = results; break; }
      }
    }
    if (items.isEmpty) {
      apollo.forEach((k, v) {
        if (v is Map && (v['__typename'] == 'Ad' || (v.containsKey('title') && v.containsKey('price')))) {
          if (v.containsKey('id') && !k.contains('FeaturedAd')) items.add(v);
        }
      });
    }

    final seenIds = <String>{};
    final uniqueItems = <dynamic>[];
    for (var item in items) {
      var v = (item is Map && item.containsKey('__ref')) ? apollo[item['__ref']] : item;
      if (v != null && v.containsKey('id')) {
        final id = v['id'].toString();
        if (seenIds.add(id)) uniqueItems.add(v);
      }
    }

    final minP = int.tryParse(precioDesde) ?? 0;
    final maxP = int.tryParse(precioHasta) ?? 999999;

    final List<Map<String, String>> res = [];
    for (var v in uniqueItems) {
      if (v['isFeatured'] == true || v['isPremium'] == true) continue;
      final titulo = v['title']?.toString() ?? '';
      final descripcion = v['description']?.toString() ?? '';
      final pRaw = v['price']?.toString() ?? '0';

      String numericOnly = pRaw.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (RegExp(r'[,.][0-9]{3}$').hasMatch(numericOnly)) {
        numericOnly = numericOnly.replaceAll(',', '').replaceAll('.', '');
      } else {
        numericOnly = numericOnly.replaceAll(',', '.');
      }
      final p = (double.tryParse(numericOnly) ?? 0).floor();
      if (p <= 1 || p < minP || p > maxP) continue;

      if (palabraClave.isNotEmpty) {
        final kw = palabraClave.toLowerCase().trim();
        final keywords = kw.split(' ').where((w) => w.length > 1).toList();
        final matched = keywords.isEmpty
            ? (titulo.toLowerCase().contains(kw) || descripcion.toLowerCase().contains(kw))
            : keywords.every((k) => titulo.toLowerCase().contains(k) || descripcion.toLowerCase().contains(k));
        if (!matched) continue;
      }

      final permalink = v['permalink']?.toString() ?? '';
      res.add({
        'id': v['id']?.toString() ?? '',
        'titulo': titulo,
        'precio': p.toString(),
        'tiempo': 'Reciente',
        'ubicacion': 'Cuba',
        'enlace': 'https://www.revolico.com${permalink.startsWith('/') ? '' : '/'}$permalink',
        'imagen': '',
        'detalles': descripcion,
      });
    }
    return res;
  } catch (_) {
    return [];
  }
}

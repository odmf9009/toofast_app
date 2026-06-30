import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const int _kForegroundNotifId = 888;
const String _kFgChannelId = 'toofast_radar_fg';

// El Foreground Service NO scrapea: su único trabajo es mantener el proceso
// de la app con prioridad de foreground (para que Android no lo mate al
// minimizar) y sostener la notificación fija. El scraping real corre en el
// isolate principal del provider, porque HeadlessInAppWebView (necesario para
// pasar la protección Cloudflare de Revolico) requiere el contexto de UI y no
// puede ejecutarse en este isolate de background.

Future<void> initBackgroundService() async {
  // Crear el canal ANTES de configurar el servicio para que startForeground()
  // nunca lance CannotPostForegroundServiceNotificationException.
  final notif = FlutterLocalNotificationsPlugin();
  await notif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  final android = notif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    _kFgChannelId, 'Radar Toofast',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  ));

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

  // El servicio solo se detiene cuando el provider lo ordena.
  service.on('detener').listen((_) {
    service.stopSelf();
  });
}

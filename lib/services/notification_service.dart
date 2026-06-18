import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications locales (singleton).
///
/// Sert aujourd'hui aux "alertes de proximite" (un lieu enregistre est tout
/// pres). L'init est appelee une fois au demarrage (main). Le lieu sur lequel
/// l'utilisateur tape est expose via [selectedPlaceId] pour que la navigation
/// puisse ouvrir la bonne fiche.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'proximity_alerts';
  static const String _channelName = 'Alertes de proximité';
  static const String _channelDesc =
      'Quand un de vos lieux enregistrés est tout près de vous.';

  bool _initialized = false;

  /// placeId de la notification tapee (par l'utilisateur). Ecoute par la
  /// navigation racine pour ouvrir la fiche correspondante.
  final ValueNotifier<String?> selectedPlaceId = ValueNotifier<String?>(null);

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (resp) {
        final id = resp.payload;
        if (id != null && id.isNotEmpty) selectedPlaceId.value = id;
      },
    );

    // App lancee depuis une notification (etat terminate).
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final id = launch!.notificationResponse?.payload;
      if (id != null && id.isNotEmpty) selectedPlaceId.value = id;
    }

    // Cree le canal Android (requis pour Android 8+).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));
  }

  /// Demande l'autorisation d'afficher des notifications (Android 13+, iOS).
  /// Renvoie true si accordee (ou non requise).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  /// Affiche une alerte de proximite pour un lieu.
  Future<void> showProximityAlert({
    required String placeId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    // Un id stable par lieu (hashCode) evite d'empiler 10 notifs pour le meme.
    await _plugin.show(
      placeId.hashCode & 0x7fffffff,
      title,
      body,
      details,
      payload: placeId,
    );
  }
}

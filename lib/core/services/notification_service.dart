import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/routes/app_pages.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String channelKey = 'alerts';
  static const String _receivePortName = 'ecovision_notification_actions';

  static ReceivePort? _receivePort;

  final List<ReceivedAction> _pendingActions = [];
  bool _navigatorReady = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    final notificationsInitialized = await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'EcoVision alerts',
          channelDescription: 'Wildlife and field updates',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: kDebugMode,
    );
    if (!notificationsInitialized) {
      throw StateError('Awesome Notifications could not be initialized.');
    }

    _initializeActionReceivePort();

    final listenersRegistered = await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
    if (!listenersRegistered) {
      throw StateError(
        'Notification action listeners could not be registered.',
      );
    }

    final initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    if (initialAction != null) {
      _pendingActions.add(initialAction);
    }

    final fcmInitialized = await AwesomeNotificationsFcm().initialize(
      onFcmTokenHandle: onFcmTokenHandle,
      onNativeTokenHandle: onNativeTokenHandle,
      onFcmSilentDataHandle: onFcmSilentDataHandle,
      debug: kDebugMode,
    );
    if (!fcmInitialized) {
      throw StateError('Firebase Cloud Messaging could not be initialized.');
    }
  }

  void onNavigatorReady() {
    _navigatorReady = true;
    for (final action in _pendingActions) {
      _navigateFromAction(action);
    }
    _pendingActions.clear();
    unawaited(_requestNotificationPermission());
  }

  Future<String> requestDeviceToken() async {
    final fcm = AwesomeNotificationsFcm();
    if (!await fcm.isFirebaseAvailable) {
      throw StateError('Firebase Cloud Messaging is unavailable.');
    }

    final token = await fcm.requestFirebaseAppToken();
    _fcmToken = token;
    return token;
  }

  Future<void> _requestNotificationPermission() async {
    if (await AwesomeNotifications().isNotificationAllowed()) return;

    final granted = await AwesomeNotifications()
        .requestPermissionToSendNotifications();
    if (!granted) {
      debugPrint('Notification permission was not granted.');
    }
  }

  void _initializeActionReceivePort() {
    if (_receivePort != null) return;

    IsolateNameServer.removePortNameMapping(_receivePortName);
    final port = ReceivePort('EcoVision notification actions');
    final registered = IsolateNameServer.registerPortWithName(
      port.sendPort,
      _receivePortName,
    );
    if (!registered) {
      port.close();
      throw StateError(
        'Notification action receive port could not be registered.',
      );
    }

    _receivePort = port;
    port.listen((message) {
      if (message is ReceivedAction) {
        _queueOrNavigate(message);
      }
    });
  }

  void _queueOrNavigate(ReceivedAction action) {
    if (!_navigatorReady) {
      _pendingActions.add(action);
      return;
    }
    _navigateFromAction(action);
  }

  void _navigateFromAction(ReceivedAction action) {
    final route = action.payload?['route']?.trim();
    if (route == null || route.isEmpty) return;

    final uri = Uri.tryParse(route);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !AppPages.routes.any((page) => page.name == uri.path)) {
      debugPrint('Ignoring notification with an unknown route: $route');
      return;
    }

    Get.offAllNamed(route, arguments: action.payload);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.actionType == ActionType.SilentAction ||
        action.actionType == ActionType.SilentBackgroundAction) {
      return;
    }

    if (_receivePort == null) {
      final sendPort = IsolateNameServer.lookupPortByName(_receivePortName);
      if (sendPort != null) {
        sendPort.send(action);
        return;
      }
    }

    instance._queueOrNavigate(action);
  }

  @pragma('vm:entry-point')
  static Future<void> onFcmTokenHandle(String token) async {
    instance._fcmToken = token;
    if (kDebugMode && token.isNotEmpty) {
      debugPrint('Firebase Cloud Messaging token: $token');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNativeTokenHandle(String token) async {
    if (kDebugMode && token.isNotEmpty) {
      debugPrint('Native push token received.');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {}
}

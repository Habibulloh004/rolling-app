import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> requestPermissionNotification() async {
  final setting = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final isAuthorized =
      setting.authorizationStatus == AuthorizationStatus.authorized;

  if (isAuthorized) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }
}

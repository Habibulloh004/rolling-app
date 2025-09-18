import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:sushi_alpha_project/NoInternat/dependecy_injection.dart';
import 'package:upgrader/upgrader.dart';

import 'LocalMemory/Boxes.dart';
import 'LocalMemory/Language.dart';
import 'LocalMemory/MaillingList.dart';
import 'Localzition/locals.dart';
import 'Notification/notification_funtions.dart';
import 'Screens/Menu/Menu.dart';
import 'Screens/Profile/Language.dart';
import 'Store/PromocodeStore.dart';
import 'firebase_options.dart';

// Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Full message: ${message.data}");
  print("Handling a background message: ${message.messageId}");

  RemoteNotification? notification = message.notification;

  if (notification == null) {
    print("No notification found in the message.");
    return;
  }

  print("Notification Title: ${notification.title}");
  print("Notification Body: ${notification.body}");

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Handle notification based on source if needed
  if (notification != null && message.data['source'] == 'order_update') {
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title ?? 'Rolling Sushi',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_launcher',
          priority: Priority.high,
          importance: Importance.max,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlutterLocalization
  final FlutterLocalization localization = FlutterLocalization.instance;
  await localization.ensureInitialized();

  // Set preferred screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  initBoxes();

  // Initialize dependency injection
  DependencyInjection.init();

  // Initialize GetX Controllers
  initializeControllers();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permissions (iOS needs this before getting tokens)
  await requestPermissionNotification();

  // Setup Firebase Messaging
  await setupFirebaseMessaging();

  // Subscribe to topics based on language
  await subscribeToTopics();

  runApp(MyApp(localization: localization));
}

// Initialize all GetX controllers
void initializeControllers() {
  // Initialize PromocodeStore as a singleton
  Get.put(PromocodeStore(), permanent: true);

  // Add other controllers here if needed
  // Get.put(CartController(), permanent: true);
  // Get.put(UserController(), permanent: true);
}

// Setup Firebase Messaging
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get FCM token
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // On iOS simulators APNs is unavailable; guard getToken() to avoid crash
  try {
    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        // Skip token retrieval on simulator or before APNs registration
        debugPrint('[FCM] APNs token not available yet; skipping getToken()');
      } else {
        final fcmToken = await messaging.getToken();
        debugPrint('[FCM] Token: $fcmToken');
      }
    } else {
      final fcmToken = await messaging.getToken();
      debugPrint('[FCM] Token: $fcmToken');
    }
  } catch (e) {
    debugPrint('[FCM] getToken error: $e');
  }

  // Initialize local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      handleNotificationTap(response.payload);
    },
  );

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Handle initial message
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    handleInitialMessage(initialMessage);
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleForegroundMessage(message, flutterLocalNotificationsPlugin, channel);
  });

  // Handle message open app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleMessageOpenedApp(message);
  });
}

// Subscribe to FCM topics based on language
Future<void> subscribeToTopics() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Unsubscribe from all topics first
  await unsubscribeFromAllTopics();

  // Subscribe to general topic
  await messaging.subscribeToTopic('all_users');

  // Subscribe to language-specific topic
  if (Language.isLanguageAvailable()) {
    String language = Language.getLanguage();
    await messaging.subscribeToTopic('all_users_$language');
    print('Subscribed to topic: all_users_$language');
  }
}

// Unsubscribe from all topics
Future<void> unsubscribeFromAllTopics() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<String> topics = [
    'all_users',
    'all_users_en',
    'all_users_ru',
    'all_users_uz',
  ];

  for (String topic in topics) {
    try {
      await messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from $topic: $e');
    }
  }
}

// Handle initial message
void handleInitialMessage(RemoteMessage message) {
  print('Initial message data: ${message.data}');

  if (message.data['type'] == 'order_update') {
    // Navigate to order tracking screen
    // Get.to(() => OrderTrackingScreen(orderId: message.data['order_id']));
  } else if (message.data['type'] == 'promocode') {
    // Navigate to promocode screen or show dialog
    // Get.to(() => PromocodeScreen());
  }
}

// Handle foreground messages
void handleForegroundMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin plugin,
    AndroidNotificationChannel channel,
    ) {
  print('Foreground message: ${message.data}');

  RemoteNotification? notification = message.notification;

  if (notification != null) {
    // Show local notification
    plugin.show(
      notification.hashCode,
      notification.title ?? 'Rolling Sushi',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_launcher',
          color: const Color(0xff004032),
          priority: Priority.high,
          importance: Importance.max,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

// Handle message when app is opened from notification
void handleMessageOpenedApp(RemoteMessage message) {
  print('Message opened app: ${message.data}');

  if (message.data['type'] == 'order_update') {
    // Navigate to order tracking
    // Get.to(() => OrderTrackingScreen(orderId: message.data['order_id']));
  } else if (message.data['type'] == 'promocode') {
    // Show promocode dialog or navigate
    try {
      final promocodeStore = Get.find<PromocodeStore>();
      // Handle promocode notification
    } catch (e) {
      print('Error finding PromocodeStore: $e');
    }
  }
}

// Handle notification tap
void handleNotificationTap(String? payload) {
  if (payload != null) {
    print('Notification tapped with payload: $payload');
    // Parse payload and navigate accordingly
  }
}

class MyApp extends StatefulWidget {
  final FlutterLocalization localization;

  const MyApp({Key? key, required this.localization}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    configLocalization();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // App is in foreground
        print('App resumed');
        // Refresh data if needed
        refreshAppData();
        break;
      case AppLifecycleState.paused:
      // App is in background
        print('App paused');
        break;
      case AppLifecycleState.detached:
      // App is terminated
        print('App detached');
        break;
      case AppLifecycleState.inactive:
      // App is inactive
        print('App inactive');
        break;
      case AppLifecycleState.hidden:
      // App is hidden
        print('App hidden');
        break;
    }
  }

  void refreshAppData() {
    // Refresh promocode data if needed
    try {
      final promocodeStore = Get.find<PromocodeStore>();
      // promocodeStore.refreshPromocodes();
    } catch (e) {
      print('Error finding PromocodeStore in refreshAppData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Rolling Sushi',
          theme: ThemeData(
            primaryColor: const Color(0xff004032),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff004032),
            ),
            useMaterial3: true,
            fontFamily: 'SF Pro Display',
          ),
          supportedLocales: widget.localization.supportedLocales,
          localizationsDelegates: widget.localization.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          home: const UpdateWrapper(),
          getPages: AppRoutes.routes,
        );
      },
    );
  }

  void configLocalization() {
    widget.localization.init(
      mapLocales: LOCALES,
      initLanguageCode: Language.isLanguageAvailable()
          ? Language.getLanguage()
          : "ru",
    );
    widget.localization.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }
}

// App Routes
class AppRoutes {
  static final routes = [
    GetPage(name: '/menu', page: () => MenuScreen()),
    GetPage(name: '/language', page: () => LanguageScreen()),
    // Add more routes as needed
  ];
}

class UpdateWrapper extends StatelessWidget {
  const UpdateWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        debugDisplayAlways: false,
        debugDisplayOnce: false,
        durationUntilAlertAgain: const Duration(days: 1),
      ),
      child: FutureBuilder<bool>(
        future: Update.checkForUpdates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          } else if (snapshot.hasError) {
            return const ErrorScreen();
          } else {
            // Check if language and mailing list are set up
            final bool isSetupComplete = Language.isLanguageAvailable() &&
                Maillinglist.isUserSubscribed();

            if (isSetupComplete) {
              return MenuScreen();
            } else {
              return LanguageScreen();
            }
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff004032),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250.w,
              height: 250.h,
              child: Lottie.asset(
                "assets/images/logoLottie.json",
                repeat: false,
                onLoaded: (composition) {
                  // Animation loaded
                },
              ),
            ),
            SizedBox(height: 20.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.sp,
              color: Colors.red,
            ),
            SizedBox(height: 20.h),
            Text(
              "Произошла ошибка",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff004032),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Пожалуйста, попробуйте еще раз",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: () {
                // Restart app
                Get.offAll(() => const UpdateWrapper());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff004032),
                padding: EdgeInsets.symmetric(
                  horizontal: 40.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Повторить",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Update checker class
class Update {
  static Future<bool> checkForUpdates() async {
    try {
      // Simulate update check
      await Future.delayed(const Duration(seconds: 2));

      // Here you would normally check with your backend
      // for app version updates

      // For now, return true to indicate no update needed
      return true;
    } catch (e) {
      print('Error checking for updates: $e');
      return true; // Continue even if update check fails
    }
  }

  // Legacy method for compatibility
  static Future<bool> isUpdateExist() async {
    return await checkForUpdates();
  }
}

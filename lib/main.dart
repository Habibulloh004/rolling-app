import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Print the full message to debug it
  print("Full message: ${message.data}");

  // Handling background message
  print("Handling a background message: ${message.messageId}");

  // Ensure notification exists
  RemoteNotification? notification = message.notification;

  if (notification == null) {
    print("No notification found in the message.");
    return; // Exit if no notification exists
  }

  print("Notification Title: ${notification.title}");
  print("Notification Body: ${notification.body}");

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create notification channel once (for the app lifecycle)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Check source of the notification

  // If message is from FCM
  // if (notification != null) {
  //   flutterLocalNotificationsPlugin.show(
  //     notification.hashCode,
  //     notification.title ?? 'No Title',
  //     notification.body ?? 'No Body',
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         channel.id,
  //         channel.name,
  //         channelDescription: channel.description,
  //         icon: 'ic_launcher',
  //       ),
  //     ),
  //   );
  // }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  initBoxes(); // Initialize Hive boxes (assuming you have a method for this)

  // Initialize dependency injection
  await DependencyInjection();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permissions
  await requestPermissionNotification();

  // Subscribe to the topic "all_users"
  //all_users

  //
  // Get the FCM token
  // FirebaseMessaging messaging = FirebaseMessaging.instance;
  //
  // String? fcmToken = await messaging.getToken();
  // print(fcmToken);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // the source.
    print("source");
    print(initialMessage.data['source']);

    Map data = initialMessage.data;
    if (initialMessage.data.isNotEmpty) {
      print('Message Data: ${initialMessage.data}');
    } else {
      print('No data in message');
    }

    RemoteNotification? notification = initialMessage.notification;
    AndroidNotification? android = initialMessage.notification?.android;

    // if (initialMessage.data['source'] == "mailing list") {
    //   flutterLocalNotificationsPlugin.show(
    //     notification.hashCode,
    //     initialMessage.data['title_en'],
    //     initialMessage.data['body_en'],
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         channel.id,
    //         channel.name,
    //         channelDescription: channel.description,
    //         icon: 'ic_launcher',
    //       ),
    //     ),
    //   );
    // }

    // if (initialMessage.data['source'] == "fcm") {
    //   flutterLocalNotificationsPlugin.show(
    //     notification.hashCode,
    //     initialMessage.data['title'],
    //     initialMessage.data['body'],
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         channel.id,
    //         channel.name,
    //         channelDescription: channel.description,
    //         icon: 'ic_launcher',
    //       ),
    //     ),
    //   );
    // }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle the message data

    // the source.
    print("source");
    print(message.data['source']);

    Map data = message.data;
    if (message.data.isNotEmpty) {
      print('Message Data: ${message.data}');
    } else {
      print('No data in message');
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    print(notification);

    if (notification?.title != null && notification?.body != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization localization = FlutterLocalization.instance;

  @override
  void initState() {
    super.initState();
    configLocalization();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return Builder(builder: (context) {
          return GetMaterialApp(
            supportedLocales: localization.supportedLocales,
            localizationsDelegates: localization.localizationsDelegates,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.1),
                child: child!,
              );
            },
            home: UpdateWrapper(),
          );
        });
      },
    );
  }

  void configLocalization() {
    localization.init(mapLocales: LOCALES, initLanguageCode: "en");
    localization.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }
}

class UpdateWrapper extends StatelessWidget {
  const UpdateWrapper() : super();

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        canDismissDialog: false,
        showIgnore: false,
        showLater: false,
        dialogStyle: UpgradeDialogStyle.material,
        shouldPopScope: () => false,
        durationUntilAlertAgain: Duration.zero,
        onUpdate: () {
          // Implement what should happen when the user agrees to update
          return true;
        },
      ),
      child: FutureBuilder<bool>(
        future: Update.isUpdateExist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else if (snapshot.hasError) {
            return ErrorScreen();
          } else {
            // final bool updateExists = snapshot.data ?? false;
            return Language.isLanguageAvailable() &&
                    Maillinglist.isUserSubscribed()
                ? MenuScreen()
                : LanguageScreen();
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Lottie.asset("assets/images/logoLottie.json", repeat: false),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("An error occurred. Please try again."),
      ),
    );
  }
}

class Update {
  static Future<bool> isUpdateExist() async {
    // Your logic to check for updates goes here
    // This is just a placeholder, replace with your actual implementation
    await Future.delayed(
        const Duration(seconds: 2)); // Simulating network delay
    return true; // or false, depending on your logic
  }
}

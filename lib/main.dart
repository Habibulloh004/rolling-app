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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_alpha_project/NoInternat/dependecy_injection.dart';
import 'package:upgrader/upgrader.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sushi_alpha_project/Consts/Colors.dart';

import 'LocalMemory/Boxes.dart';
import 'LocalMemory/Language.dart';
import 'LocalMemory/MaillingList.dart';
import 'Localzition/locals.dart';
import 'Notification/notification_funtions.dart';
import 'Screens/Menu/Menu.dart';
import 'Screens/Profile/Language.dart';
import 'Store/PromocodeStore.dart';
import 'firebase_options.dart';

// const String SERVER_URL = 'http://192.168.1.9:8000';
const String SERVER_URL = 'https://sushiserver.onrender.com';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Track if messaging has been initialized
bool _messagingInitialized = false;

int buildAndroidNotificationId(RemoteMessage message) {
  final base = message.messageId ??
      '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}-${message.data.hashCode}';
  return base.hashCode & 0x7fffffff;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("🔥 Background Message Received");
  print("Message ID: ${message.messageId}");
  print("Full message data: ${message.data}");
  
  RemoteNotification? notification = message.notification;

  if (notification == null) {
    print("❌ No notification found in the message.");
    return;
  }

  if (Platform.isIOS) {
    print('ℹ️ iOS background: letting system/APNs present notification; skipping local show.');
    return;
  }

  print("📱 Notification Title: ${notification.title}");
  print("📱 Notification Body: ${notification.body}");

  if (Platform.isAndroid) {
    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'alerts_channel',
      'Alerts',
      description: 'Always alerts with sound and heads-up for Rolling Sushi.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xff004032),
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertsChannel);
  }

  String channelId = 'alerts_channel';
  Priority priority = Priority.max;
  Importance importance = Importance.max;

  await flutterLocalNotificationsPlugin.show(
    buildAndroidNotificationId(message),
    notification.title ?? 'Rolling Sushi',
    notification.body ?? 'New notification received',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Alerts',
        channelDescription: 'Always alerts with sound and heads-up for Rolling Sushi.',
        icon: '@drawable/ic_notification',
        color: const Color(0xff004032),
        priority: priority,
        importance: importance,
        playSound: true,
        enableVibration: true,
        onlyAlertOnce: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    ),
    payload: json.encode({
      'data': message.data,
      'notification': {
        'title': notification.title,
        'body': notification.body,
      }
    }),
  );

  print("✅ Background notification displayed successfully");
}

// ============================================================================
// MAIN - MINIMAL INITIALIZATION ONLY
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Initialize Firebase (required for background messages)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // STEP 2: Set background handler (required for background messages)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // STEP 3: Initialize local notifications infrastructure only
  await initializeLocalNotifications();

  // STEP 4: Initialize other essential components
  final FlutterLocalization localization = FlutterLocalization.instance;
  await localization.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await initBoxes();
  
  DependencyInjection.init();
  initializeControllers();

  // ⚠️ DO NOT REQUEST PERMISSIONS OR SETUP MESSAGING HERE
  // These will be called AFTER user interacts with the UI

  print('✅ App initialized - UI ready to show');
  
  runApp(MyApp(localization: localization));
}

// ============================================================================
// DELAYED MESSAGING INITIALIZATION - Call this AFTER UI interaction
// ============================================================================
Future<void> initializeMessagingAfterUserInteraction() async {
  if (_messagingInitialized) {
    print('ℹ️ Messaging already initialized, skipping');
    return;
  }

  try {
    print('🚀 Starting messaging initialization after user interaction...');

    // STEP 1: Request permissions
    await requestNotificationPermissions();

    // STEP 2: Setup Firebase Messaging
    await setupFirebaseMessaging();

    // STEP 3: Subscribe to topics
    await subscribeToTopics();

    _messagingInitialized = true;
    print('✅ Messaging initialization completed successfully');

    // Save initialization status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('messaging_initialized', true);
    await prefs.setInt('messaging_initialized_at', DateTime.now().millisecondsSinceEpoch);

  } catch (e) {
    print('❌ Error during messaging initialization: $e');
    // Don't block the app - user can still use it without notifications
  }
}

// Check if messaging was previously initialized
Future<bool> wasMessagingInitialized() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('messaging_initialized') ?? false;
  } catch (e) {
    print('❌ Error checking messaging initialization status: $e');
    return false;
  }
}

// ============================================================================
// HIVE INITIALIZATION
// ============================================================================
Future<void> initializeHiveBoxes() async {
  try {
    await Hive.openBox('language');
    await Hive.openBox('mailingList');
    await Hive.openBox('promocodes');
    await Hive.openBox('settings');
    print('✅ All Hive boxes initialized successfully');
  } catch (e) {
    print('❌ Error initializing Hive boxes: $e');
    try {
      await Hive.openBox('language');
      await Hive.openBox('mailingList');
    } catch (fallbackError) {
      print('❌ Fallback Hive initialization failed: $fallbackError');
    }
  }
}

void initializeControllers() {
  Get.put(PromocodeStore(), permanent: true);
}

// ============================================================================
// PERMISSION AND MESSAGING SETUP
// ============================================================================
Future<void> requestNotificationPermissions() async {
  try {
    print('📋 Requesting notification permissions...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );
      
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('✅ iOS permissions requested');
    }

    if (Platform.isAndroid) {
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        print('✅ Android notifications permission requested');
      } catch (e) {
        print('⚠️ Android notifications permission request failed: $e');
      }
      
      try {
        await messaging.requestPermission();
      } catch (e) {
        print('⚠️ FirebaseMessaging.requestPermission on Android failed: $e');
      }
    }

    print('✅ Notification permissions requested successfully');
  } catch (e) {
    print('❌ Error requesting permissions: $e');
  }
}

Future<void> initializeLocalNotifications() async {
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

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
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    await createNotificationChannels();
    
    print('✅ Local notifications initialized successfully');
  } catch (e) {
    print('❌ Error initializing local notifications: $e');
  }
}

Future<void> createNotificationChannels() async {
  if (Platform.isAndroid) {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('❌ Android notification plugin not available');
      return;
    }

    const AndroidNotificationChannel highImportanceChannel =
        AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important notifications like order updates and urgent messages.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xff004032),
    );

    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'alerts_channel',
      'Alerts',
      description: 'Always alerts with sound and heads-up for Rolling Sushi.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xff004032),
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'General app notifications and updates.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel promotionalChannel =
        AndroidNotificationChannel(
      'promotional_channel',
      'Promotional Notifications',
      description: 'Special offers, discounts, and promotional content.',
      importance: Importance.defaultImportance,
      playSound: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(highImportanceChannel);
    await androidPlugin.createNotificationChannel(alertsChannel);
    await androidPlugin.createNotificationChannel(generalChannel);
    await androidPlugin.createNotificationChannel(promotionalChannel);
    
    print('✅ Android notification channels created successfully');
  }
}

void onDidReceiveNotificationResponse(NotificationResponse response) async {
  print('📱 Notification response received');
  print('📊 Action ID: ${response.actionId}');
  print('📊 Payload: ${response.payload}');

  try {
    if (response.payload != null) {
      final payloadData = json.decode(response.payload!);
      final messageData = payloadData['data'] as Map<String, dynamic>? ?? {};
      
      switch (response.actionId) {
        case 'view_order':
          _handleOrderAction(messageData);
          break;
        case 'view_promocode':
          _handlePromocodeAction(messageData);
          break;
        case 'dismiss':
          print('📱 Notification dismissed');
          break;
        default:
          handleNotificationTap(response.payload);
      }
    }
  } catch (e) {
    print('❌ Error processing notification response: $e');
    handleNotificationTap(response.payload);
  }
}

void _handleOrderAction(Map<String, dynamic> data) {
  print('🍱 Handling order action');
  
  final orderId = data['order_id'];
  if (orderId != null) {
    print('🎯 Would navigate to order: $orderId');
  } else {
    Get.offAll(() => MenuScreen());
    print('🎯 Navigated to menu screen');
  }
}

void _handlePromocodeAction(Map<String, dynamic> data) {
  print('🎁 Handling promocode action');
  
  try {
    final promocodeStore = Get.find<PromocodeStore>();
    
    final promocodeId = data['promocode_id'];
    if (promocodeId != null) {
      print('🎯 Would navigate to promocode: $promocodeId');
    } else {
      Get.offAll(() => MenuScreen());
      print('🎯 Navigated to menu screen');
    }
  } catch (e) {
    print('❌ Error handling promocode action: $e');
    Get.offAll(() => MenuScreen());
  }
}

// ============================================================================
// TOKEN MANAGEMENT
// ============================================================================
Future<void> sendTokenToServer(String token) async {
  try {
    String language;
    try {
      language = Language.isLanguageAvailable() ? Language.getLanguage() : 'ru';
    } catch (e) {
      print('⚠️ Error getting language, using default: $e');
      language = 'ru';
    }
    
    print('📤 Registering token with server...');
    print('🔑 Full FCM token: $token');
    print('🔑 Token: ${token.substring(0, 20)}...');
    print('🌍 Language: $language');
    
    final response = await http.post(
      Uri.parse('$SERVER_URL/tokens/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'deviceToken': token,
        'language': language,
        'userId': null,
      }),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('✅ Token registered successfully');
      print('📊 Server response: ${responseData['message']}');
      print('🔍 Token valid: ${responseData['tokenValid']}');
      
      if (responseData['subscribedTopics'] != null) {
        print('📢 Subscribed to topics: ${responseData['subscribedTopics']}');
      }
    } else {
      print('❌ Failed to register token: ${response.statusCode}');
      print('📝 Response: ${response.body}');
      await _sendTokenToServerLegacy(token, language);
    }
  } catch (e) {
    print('❌ Error sending token to server: $e');
    
    try {
      String language = 'ru';
      try {
        language = Language.isLanguageAvailable() ? Language.getLanguage() : 'ru';
      } catch (langError) {
        print('⚠️ Using fallback language due to error: $langError');
      }
      await _sendTokenToServerLegacy(token, language);
    } catch (fallbackError) {
      print('❌ Fallback also failed: $fallbackError');
    }
  }
}

Future<void> _sendTokenToServerLegacy(String token, String language) async {
  try {
    print('🔄 Trying legacy endpoint...');
    
    final response = await http.post(
      Uri.parse('$SERVER_URL/subscribe'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'deviceToken': token,
        'language': language,
      }),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      print('✅ Token registered with legacy endpoint');
    } else {
      throw Exception('Legacy endpoint failed: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Legacy registration failed: $e');
  }
}

Future<void> updateTokenLanguage(String token, String newLanguage) async {
  try {
    print('🔄 Updating token language to: $newLanguage');
    
    final response = await http.put(
      Uri.parse('$SERVER_URL/tokens/language'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'deviceToken': token,
        'newLanguage': newLanguage,
      }),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('✅ Language updated successfully');
      print('📊 Old: ${responseData['oldLanguage']}, New: ${responseData['newLanguage']}');
    } else {
      print('❌ Failed to update language: ${response.statusCode}');
      print('📝 Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error updating token language: $e');
  }
}

Future<void> unregisterTokenFromServer(String token) async {
  try {
    print('🗑️ Unregistering token from server...');
    
    final response = await http.delete(
      Uri.parse('$SERVER_URL/tokens/unregister'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'deviceToken': token,
      }),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      print('✅ Token unregistered successfully');
    } else {
      print('❌ Failed to unregister token: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error unregistering token: $e');
  }
}

Future<void> setupFirebaseMessaging() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? fcmToken;
    int retryCount = 0;
    const maxRetries = 3;
    
    while (fcmToken == null && retryCount < maxRetries) {
      try {
        fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          print('🔑 FCM Token obtained: ${fcmToken.substring(0, 20)}...');
          break;
        }
      } catch (e) {
        retryCount++;
        print('❌ Attempt $retryCount failed to get FCM token: $e');
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    if (fcmToken != null) {
      await sendTokenToServer(fcmToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
      await prefs.setInt('token_registered_at', DateTime.now().millisecondsSinceEpoch);
    } else {
      print('❌ Failed to obtain FCM token after $maxRetries attempts');
    }

    messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final oldToken = prefs.getString('fcm_token');
        
        if (oldToken != null && oldToken != newToken) {
          await unregisterTokenFromServer(oldToken);
        }
        
        await sendTokenToServer(newToken);
        
        await prefs.setString('fcm_token', newToken);
        await prefs.setInt('token_registered_at', DateTime.now().millisecondsSinceEpoch);
        
        print('✅ Token refresh completed successfully');
      } catch (e) {
        print('❌ Error during token refresh: $e');
      }
    });

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from notification');
      await Future.delayed(const Duration(milliseconds: 1500));
      handleInitialMessage(initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received');
      print('📊 Data: ${message.data}');
      handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from background notification');
      print('📊 Data: ${message.data}');
      handleMessageOpenedApp(message);
    });

    print('✅ Firebase Messaging setup completed successfully');
  } catch (e) {
    print('❌ Critical error setting up Firebase Messaging: $e');
  }
}

Future<void> subscribeToTopics() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('fcm_token');
    final previousLanguage = prefs.getString('topic_language');
    
    if (currentToken == null) {
      print('❌ No FCM token available for topic subscription');
      return;
    }

    await messaging.subscribeToTopic('all_users');
    print('✅ Subscribed to topic: all_users');

    String language;
    try {
      language = Language.isLanguageAvailable() ? Language.getLanguage() : 'ru';
      print('🌍 Current language for topic: $language');
    } catch (e) {
      print('⚠️ Error getting language for topic subscription, using default: $e');
      language = 'ru';
    }

    const supportedLanguages = ['en', 'ru', 'uz'];

    for (final code in supportedLanguages) {
      if (code == language) continue;
      try {
        await messaging.unsubscribeFromTopic('all_users_$code');
        print('✅ Unsubscribed from topic: all_users_$code');
      } catch (e) {
        print('⚠️ Error unsubscribing from all_users_$code: $e');
      }
    }

    await messaging.subscribeToTopic('all_users_$language');
    print('✅ Subscribed to topic: all_users_$language');
    
    try {
      if (previousLanguage != language) {
        await updateTokenLanguage(currentToken, language);
      }
    } catch (e) {
      print('⚠️ Warning: Could not update token language on server: $e');
    }
    
    await prefs.setInt('last_topic_subscription', DateTime.now().millisecondsSinceEpoch);
    await prefs.setString('topic_language', language);
    
  } catch (e) {
    print('❌ Error subscribing to topics: $e');
  }
}

Future<void> unsubscribeFromAllTopics() async {
  try {
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
        print('✅ Unsubscribed from topic: $topic');
      } catch (e) {
        print('❌ Error unsubscribing from $topic: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_topic_subscription');
    
  } catch (e) {
    print('❌ Error in unsubscribeFromAllTopics: $e');
  }
}

Future<void> onLanguageChanged(String newLanguage) async {
  try {
    print('🌍 Language changed to: $newLanguage');
    
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('fcm_token');
    
    if (currentToken == null) {
      print('❌ No FCM token available for language update');
      return;
    }
    
    try {
      await updateTokenLanguage(currentToken, newLanguage);
    } catch (e) {
      print('⚠️ Warning: Could not update language on server: $e');
    }
    
    await subscribeToTopics();
    
    print('✅ Language change completed successfully');
  } catch (e) {
    print('❌ Error handling language change: $e');
  }
}

// ============================================================================
// MESSAGE HANDLERS
// ============================================================================
void handleInitialMessage(RemoteMessage message) {
  print('🚀 Initial message data: ${message.data}');

  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageType = message.data['type'] ?? message.data['messageType'];
      
      switch (messageType) {
        case 'order_update':
        case 'orderReady':
          final orderId = message.data['order_id'];
          if (orderId != null) {
            print('🎯 Would navigate to order tracking: $orderId');
          } else {
            Get.offAll(() => MenuScreen());
          }
          break;
          
        case 'promocode':
        case 'newPromotion':
          final promocodeId = message.data['promocode_id'];
          if (promocodeId != null) {
            print('🎯 Would navigate to promocode: $promocodeId');
          } else {
            Get.offAll(() => MenuScreen());
          }
          break;
          
        case 'general':
        default:
          Get.offAll(() => MenuScreen());
          break;
      }
    });
  } catch (e) {
    print('❌ Error handling initial message: $e');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => MenuScreen());
    });
  }
}

void handleForegroundMessage(RemoteMessage message) {
  print('🔔 === FOREGROUND MESSAGE RECEIVED ===');
  print('🔔 Message ID: ${message.messageId}');
  print('🔔 Data: ${message.data}');
  print('🔔 Notification Title: ${message.notification?.title}');
  print('🔔 Notification Body: ${message.notification?.body}');

  RemoteNotification? notification = message.notification;

  if (notification == null) {
    print('❌ No notification content found');
    return;
  }

  if (Platform.isIOS) {
    print('ℹ️ iOS foreground: system will present notification; skipping local show.');
    return;
  }

  try {
    String channelId = 'alerts_channel';
    String channelName = 'Alerts';
    String channelDescription = 'Always alerts with sound and heads-up for Rolling Sushi.';
    Priority priority = Priority.max;
    Importance importance = Importance.max;
    
    final messageType = message.data['messageType'] ?? message.data['type'];

    flutterLocalNotificationsPlugin.show(
      buildAndroidNotificationId(message),
      notification.title ?? 'Rolling Sushi',
      notification.body ?? 'You have a new notification',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          icon: '@drawable/ic_notification',
          color: const Color(0xff004032),
          priority: priority,
          importance: importance,
          playSound: true,
          enableVibration: true,
          onlyAlertOnce: false,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          actions: _getNotificationActions(messageType),
          styleInformation: _getNotificationStyle(message),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      payload: json.encode({
        'data': message.data,
        'notification': {
          'title': notification.title,
          'body': notification.body,
        }
      }),
    );
    
    print('✅ Foreground notification displayed successfully');
  } catch (e) {
    print('❌ Error displaying foreground notification: $e');
  }
}

List<AndroidNotificationAction>? _getNotificationActions(String? messageType) {
  switch (messageType) {
    case 'orderReady':
    case 'order_update':
      return [
        const AndroidNotificationAction(
          'view_order',
          'View Order',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: false,
        ),
      ];
    case 'newPromotion':
    case 'promocode':
      return [
        const AndroidNotificationAction(
          'view_promocode',
          'View Offer',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Later',
          showsUserInterface: false,
        ),
      ];
    default:
      return null;
  }
}

StyleInformation? _getNotificationStyle(RemoteMessage message) {
  final body = message.notification?.body;
  if (body != null && body.length > 50) {
    return BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: message.notification?.title,
      htmlFormatContentTitle: false,
      summaryText: 'Rolling Sushi',
      htmlFormatSummaryText: false,
    );
  }
  return null;
}

void handleMessageOpenedApp(RemoteMessage message) {
  print('📱 App opened from background notification');
  print('📊 Message data: ${message.data}');

  try {
    final messageType = message.data['messageType'] ?? message.data['type'];
    
    switch (messageType) {
      case 'order_update':
      case 'orderReady':
        final orderId = message.data['order_id'];
        if (orderId != null) {
          print('🎯 Would navigate to order tracking: $orderId');
        } else {
          Get.offAll(() => MenuScreen());
        }
        break;
        
      case 'promocode':
      case 'newPromotion':
        try {
          final promocodeStore = Get.find<PromocodeStore>();
          final promocodeId = message.data['promocode_id'];
          
          if (promocodeId != null) {
            print('🎯 Would navigate to promocode: $promocodeId');
          } else {
            Get.offAll(() => MenuScreen());
          }
        } catch (e) {
          print('❌ Error finding PromocodeStore: $e');
          Get.offAll(() => MenuScreen());
        }
        break;
        
      default:
        Get.offAll(() => MenuScreen());
        break;
    }
  } catch (e) {
    print('❌ Error handling message opened app: $e');
    Get.offAll(() => MenuScreen());
  }
}

void handleNotificationTap(String? payload) {
  if (payload == null) return;
  
  try {
    print('📱 Processing notification tap...');
    print('📊 Payload: $payload');
    
    final payloadData = json.decode(payload);
    final messageData = payloadData['data'] as Map<String, dynamic>? ?? {};
    final messageType = messageData['messageType'] ?? messageData['type'];
    
    switch (messageType) {
      case 'order_update':
      case 'orderReady':
        _handleOrderAction(messageData);
        break;
      case 'promocode':
      case 'newPromotion':
        _handlePromocodeAction(messageData);
        break;
      default:
        Get.offAll(() => MenuScreen());
        break;
    }
  } catch (e) {
    print('❌ Error processing notification tap: $e');
    Get.offAll(() => MenuScreen());
  }
}

// ============================================================================
// APP LIFECYCLE HANDLER
// ============================================================================
class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - checking token status');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('📱 App paused');
        break;
      case AppLifecycleState.detached:
        print('📱 App detached - performing cleanup');
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;
      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    try {
      // Only refresh if messaging was already initialized
      if (_messagingInitialized) {
        await _refreshTokenIfNeeded();
        await _checkTopicSubscriptions();
        _refreshAppData();
      }
    } catch (e) {
      print('❌ Error handling app resumed: $e');
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRegistration = prefs.getInt('token_registered_at');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastRegistration == null || (now - lastRegistration) > 24 * 60 * 60 * 1000) {
        print('🔄 Token needs refresh due to age');
        
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        final currentToken = await messaging.getToken();
        
        if (currentToken != null) {
          final storedToken = prefs.getString('fcm_token');
          
          if (storedToken != currentToken) {
            print('🔄 Token changed, updating server...');
            await sendTokenToServer(currentToken);
            await prefs.setString('fcm_token', currentToken);
          }
          
          await prefs.setInt('token_registered_at', now);
        }
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
    }
  }

  Future<void> _checkTopicSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSubscription = prefs.getInt('last_topic_subscription');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastSubscription == null || (now - lastSubscription) > 7 * 24 * 60 * 60 * 1000) {
        print('🔄 Re-subscribing to topics due to age');
        await subscribeToTopics();
      }
    } catch (e) {
      print('❌ Error checking topic subscriptions: $e');
    }
  }

  void _refreshAppData() {
    try {
      final promocodeStore = Get.find<PromocodeStore>();
      print('🔄 Refreshing app data');
    } catch (e) {
      print('❌ Error refreshing app data: $e');
    }
  }

  Future<void> _handleAppDetached() async {
    try {
      print('🧹 Performing app cleanup');
    } catch (e) {
      print('❌ Error during app detach cleanup: $e');
    }
  }
}

// ============================================================================
// UI COMPONENTS
// ============================================================================
class GlobalSafeAreaWrapper extends StatelessWidget {
  final Widget child;
  
  const GlobalSafeAreaWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Container(
      color: cDarkGreen,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: child,
    );
  }
}

class MyApp extends StatefulWidget {
  final FlutterLocalization localization;

  const MyApp({Key? key, required this.localization}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLifecycleHandler _lifecycleHandler;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _lifecycleHandler = AppLifecycleHandler();
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
    
    configLocalization();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.removeObserver(_lifecycleHandler);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xff004032),
        );
        return GetMaterialApp(
          title: 'Rolling Sushi',
          theme: ThemeData(
            primaryColor: const Color(0xff004032),
            colorScheme: colorScheme,
            scaffoldBackgroundColor: colorScheme.surface,
            useMaterial3: true,
            fontFamily: 'SF Pro Display',
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xff004032),
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Color(0xff004032),
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xff004032),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff004032),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          supportedLocales: widget.localization.supportedLocales,
          localizationsDelegates: widget.localization.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: GlobalSafeAreaWrapper(
                child: child!,
              ),
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
    
    if (locale != null && _messagingInitialized) {
      final languageCode = locale.languageCode;
      if (['en', 'uz', 'ru'].contains(languageCode)) {
        onLanguageChanged(languageCode);
      }
    }
  }
}

class AppRoutes {
  static final routes = [
    GetPage(name: '/menu', page: () => MenuScreen()),
    GetPage(name: '/language', page: () => LanguageScreen()),
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
            print('❌ Update check error: ${snapshot.error}');
            return const ErrorScreen();
          } else {
            bool isSetupComplete = false;
            try {
              final isLanguageSet = Language.isLanguageAvailable();
              final isUserSubscribed = Maillinglist.isUserSubscribed();
              
              isSetupComplete = isLanguageSet && isUserSubscribed;
              
              print('🔍 Setup status - Language: $isLanguageSet, Subscribed: $isUserSubscribed, Complete: $isSetupComplete');
            } catch (e) {
              print('⚠️ Error checking setup completion: $e');
              isSetupComplete = false;
            }

            if (isSetupComplete) {
              // ✅ User has completed setup - Initialize messaging
              _initializeMessagingIfNeeded();
              return MenuScreen();
            } else {
              // ⚠️ User needs to complete setup first
              return LanguageScreen();
            }
          }
        },
      ),
    );
  }

  // Initialize messaging after user completes setup
  void _initializeMessagingIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if already initialized
      final wasInitialized = await wasMessagingInitialized();
      if (!wasInitialized && !_messagingInitialized) {
        print('🚀 User setup complete - initializing messaging now...');
        await initializeMessagingAfterUserInteraction();
      } else {
        print('ℹ️ Messaging already initialized');
      }
    });
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  print('🎬 Lottie animation loaded');
                },
              ),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                "Пожалуйста, проверьте подключение к интернету и попробуйте еще раз",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.offAll(() => const UpdateWrapper());
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      "Повторить",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004032),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.offAll(() => LanguageScreen());
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(
                      "Настройки",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff004032),
                      side: const BorderSide(color: Color(0xff004032)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Update {
  static Future<bool> checkForUpdates() async {
    try {
      print('🔄 Checking for updates...');
      await Future.delayed(const Duration(seconds: 2));
      print('✅ Update check completed');
      return true;
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return true;
    }
  }

  static Future<bool> isUpdateExist() async {
    try {
      return await checkForUpdates();
    } catch (e) {
      print('❌ Error checking if update exists: $e');
      return false;
    }
  }
}

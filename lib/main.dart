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
import 'Store/PromocodeStore.dart'; // 192.168.1.41
import 'firebase_options.dart';

// Configuration - Replace with your actual server URL
const String SERVER_URL = 'http://192.168.1.41:3000'; // Change this to your production URL

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Build a stable, unique notification ID for Android to prevent
// unintended replacements or cancellations when multiple notifications arrive.
int buildAndroidNotificationId(RemoteMessage message) {
  final base = message.messageId ??
      '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}-${message.data.hashCode}';
  // Ensure 32-bit positive int
  return base.hashCode & 0x7fffffff;
}

// Background message handler for Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background
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

  // On iOS, APNs will present notifications when the app is in background
  // if the message contains a notification payload. Showing a local
  // notification as well would cause a duplicate. Skip local show on iOS.
  if (Platform.isIOS) {
    print('ℹ️ iOS background: letting system/APNs present notification; skipping local show.');
    return;
  }

  print("📱 Notification Title: ${notification.title}");
  print("📱 Notification Body: ${notification.body}");

  // Ensure alerts channel exists for Android background isolate
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

  // Always alert on Android using alerts channel
  String channelId = 'alerts_channel';
  Priority priority = Priority.max;
  Importance importance = Importance.max;

  // Show notification for ALL types (Android only; iOS is skipped above)
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background handler IMMEDIATELY after Firebase init
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Then initialize local notifications
  await initializeLocalNotifications();

  // Initialize other components
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

  // Request permissions and setup messaging
  await requestNotificationPermissions();
  await setupFirebaseMessaging();
  await subscribeToTopics();

  runApp(MyApp(localization: localization));
}

// FIXED: Proper Hive box initialization
Future<void> initializeHiveBoxes() async {
  try {
    // Open all required boxes
    await Hive.openBox('language');
    await Hive.openBox('mailingList');
    await Hive.openBox('promocodes');
    await Hive.openBox('settings');
    
    print('✅ All Hive boxes initialized successfully');
  } catch (e) {
    print('❌ Error initializing Hive boxes: $e');
    // Create fallback boxes or handle error appropriately
    try {
      await Hive.openBox('language');
      await Hive.openBox('mailingList');
    } catch (fallbackError) {
      print('❌ Fallback Hive initialization failed: $fallbackError');
    }
  }
}

// Initialize all GetX controllers
void initializeControllers() {
  Get.put(PromocodeStore(), permanent: true);
}

// Request notification permissions with detailed handling
Future<void> requestNotificationPermissions() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // iOS-specific: Request provisional authorization first
    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true, // Enable provisional
        sound: true,
      );
      
      // For iOS, also request notification permissions
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // Android 13+ runtime notification permission
    if (Platform.isAndroid) {
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        print('⚠️ Android notifications permission request failed: $e');
      }
      try {
        await messaging.requestPermission();
      } catch (e) {
        print('⚠️ FirebaseMessaging.requestPermission on Android failed: $e');
      }
    }

    // Rest of your permission code...
  } catch (e) {
    print('❌ Error requesting permissions: $e');
  }
}

// Initialize local notifications with comprehensive setup
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

    // Create notification channels for Android
    await createNotificationChannels();
    
    print('✅ Local notifications initialized successfully');
  } catch (e) {
    print('❌ Error initializing local notifications: $e');
  }
}

// Create comprehensive notification channels for Android
Future<void> createNotificationChannels() async {
  if (Platform.isAndroid) {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('❌ Android notification plugin not available');
      return;
    }

    // High importance channel for urgent notifications
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

    // Alerts channel: always heads-up with sound for all app notifications
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

    // General channel for regular notifications
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

    // Promotional channel for offers and promotions
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

// Enhanced notification response handling
void onDidReceiveNotificationResponse(NotificationResponse response) async {
  print('📱 Notification response received');
  print('📊 Action ID: ${response.actionId}');
  print('📊 Payload: ${response.payload}');

  try {
    if (response.payload != null) {
      final payloadData = json.decode(response.payload!);
      final messageData = payloadData['data'] as Map<String, dynamic>? ?? {};
      
      // Handle different action types
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
          // Default tap action
          handleNotificationTap(response.payload);
      }
    }
  } catch (e) {
    print('❌ Error processing notification response: $e');
    // Fallback to default handling
    handleNotificationTap(response.payload);
  }
}

// Handle order-related notification actions
void _handleOrderAction(Map<String, dynamic> data) {
  print('🍱 Handling order action');
  
  final orderId = data['order_id'];
  if (orderId != null) {
    // Navigate to order tracking screen
    // Get.to(() => OrderTrackingScreen(orderId: orderId));
    print('🎯 Would navigate to order: $orderId');
  } else {
    // Navigate to general orders screen or menu
    Get.offAll(() => MenuScreen());
    print('🎯 Navigated to menu screen');
  }
}

// Handle promocode-related notification actions
void _handlePromocodeAction(Map<String, dynamic> data) {
  print('🎁 Handling promocode action');
  
  try {
    final promocodeStore = Get.find<PromocodeStore>();
    
    final promocodeId = data['promocode_id'];
    if (promocodeId != null) {
      // Navigate to specific promocode
      print('🎯 Would navigate to promocode: $promocodeId');
      // Get.to(() => PromocodeDetailScreen(promocodeId: promocodeId));
    } else {
      // Navigate to general menu or promocodes section
      Get.offAll(() => MenuScreen());
      print('🎯 Navigated to menu screen');
    }
  } catch (e) {
    print('❌ Error handling promocode action: $e');
    Get.offAll(() => MenuScreen());
  }
}

// FIXED: Send token to server with proper error handling and fallbacks
Future<void> sendTokenToServer(String token) async {
  try {
    // Get current language with safe fallback
    String language;
    try {
      language = Language.isLanguageAvailable() ? Language.getLanguage() : 'ru';
    } catch (e) {
      print('⚠️ Error getting language, using default: $e');
      language = 'ru'; // Safe fallback
    }
    
    print('📤 Registering token with server...');
    print('🔑 Token: ${token}');
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
        'userId': null, // Add user ID if available from your app
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
      
      // Try fallback to legacy endpoint
      await _sendTokenToServerLegacy(token, language);
    }
  } catch (e) {
    print('❌ Error sending token to server: $e');
    
    // Try fallback to legacy endpoint
    try {
      String language = 'ru'; // Safe fallback language
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

// Fallback to legacy subscribe endpoint
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

// Update token language on server with safe language handling
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

// Unregister token from server
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

// Enhanced Firebase Messaging setup with retry mechanisms
Future<void> setupFirebaseMessaging() async {
  try {
    // Background message handler is registered in main(); avoid duplicate registration here

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get FCM token with retry mechanism
    String? fcmToken;
    int retryCount = 0;
    const maxRetries = 3;
    
    while (fcmToken == null && retryCount < maxRetries) {
      try {
        fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          print('🔑 FCM Token obtained: ${fcmToken}');
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
      // Send token to server
      await sendTokenToServer(fcmToken);
      
      // Store token locally for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
      await prefs.setInt('token_registered_at', DateTime.now().millisecondsSinceEpoch);
    } else {
      print('❌ Failed to obtain FCM token after $maxRetries attempts');
    }

    // Listen to token refresh with improved handling
    messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      
      try {
        // Get old token from storage
        final prefs = await SharedPreferences.getInstance();
        final oldToken = prefs.getString('fcm_token');
        
        if (oldToken != null && oldToken != newToken) {
          // Unregister old token
          await unregisterTokenFromServer(oldToken);
        }
        
        // Register new token
        await sendTokenToServer(newToken);
        
        // Update stored token
        await prefs.setString('fcm_token', newToken);
        await prefs.setInt('token_registered_at', DateTime.now().millisecondsSinceEpoch);
        
        print('✅ Token refresh completed successfully');
      } catch (e) {
        print('❌ Error during token refresh: $e');
      }
    });

    // Handle initial message (when app is opened from notification)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from notification');
      // Delay to ensure app is fully loaded
      await Future.delayed(const Duration(milliseconds: 1500));
      handleInitialMessage(initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received');
      print('📊 Data: ${message.data}');
      handleForegroundMessage(message);
    });

    // Handle message when app is opened from background
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

// FIXED: Enhanced subscribe to topics with comprehensive error handling
Future<void> subscribeToTopics() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get current token
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('fcm_token');
    
    if (currentToken == null) {
      print('❌ No FCM token available for topic subscription');
      return;
    }

    // Subscribe to general topic
    await messaging.subscribeToTopic('all_users');
    print('✅ Subscribed to topic: all_users');

    // Subscribe to language-specific topic with safe language handling
    String language;
    try {
      language = Language.isLanguageAvailable() ? Language.getLanguage() : 'ru';
      print('🌍 Current language for topic: $language');
    } catch (e) {
      print('⚠️ Error getting language for topic subscription, using default: $e');
      language = 'ru'; // Safe fallback
    }
    
    await messaging.subscribeToTopic('all_users_$language');
    print('✅ Subscribed to topic: all_users_$language');
    
    // Also make sure server has the latest language (but don't fail if it doesn't work)
    try {
      await updateTokenLanguage(currentToken, language);
    } catch (e) {
      print('⚠️ Warning: Could not update token language on server: $e');
      // Continue anyway - this is not critical for app functionality
    }
    
    // Store subscription info
    await prefs.setInt('last_topic_subscription', DateTime.now().millisecondsSinceEpoch);
    
  } catch (e) {
    print('❌ Error subscribing to topics: $e');
  }
}

// Unsubscribe from all topics with comprehensive cleanupba
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
    
    // Clear subscription info
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_topic_subscription');
    
  } catch (e) {
    print('❌ Error in unsubscribeFromAllTopics: $e');
  }
}

// Function to call when language changes in the app
Future<void> onLanguageChanged(String newLanguage) async {
  try {
    print('🌍 Language changed to: $newLanguage');
    
    // Get current token
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('fcm_token');
    
    if (currentToken == null) {
      print('❌ No FCM token available for language update');
      return;
    }
    
    // Update language on server (but don't fail if it doesn't work)
    try {
      await updateTokenLanguage(currentToken, newLanguage);
    } catch (e) {
      print('⚠️ Warning: Could not update language on server: $e');
    }
    
    // Re-subscribe to topics with new language
    await subscribeToTopics();
    
    print('✅ Language change completed successfully');
  } catch (e) {
    print('❌ Error handling language change: $e');
  }
}

// Handle initial message with improved routing and error handling
void handleInitialMessage(RemoteMessage message) {
  print('🚀 Initial message data: ${message.data}');

  try {
    // Wait for app to be ready before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageType = message.data['type'] ?? message.data['messageType'];
      
      switch (messageType) {
        case 'order_update':
        case 'orderReady':
          final orderId = message.data['order_id'];
          if (orderId != null) {
            // Navigate to order tracking screen
            // Get.to(() => OrderTrackingScreen(orderId: orderId));
            print('🎯 Would navigate to order tracking: $orderId');
          } else {
            Get.offAll(() => MenuScreen());
          }
          break;
          
        case 'promocode':
        case 'newPromotion':
          final promocodeId = message.data['promocode_id'];
          if (promocodeId != null) {
            // Navigate to specific promocode
            // Get.to(() => PromocodeDetailScreen(promocodeId: promocodeId));
            print('🎯 Would navigate to promocode: $promocodeId');
          } else {
            Get.offAll(() => MenuScreen());
          }
          break;
          
        case 'general':
        default:
          // Navigate to main menu
          Get.offAll(() => MenuScreen());
          break;
      }
    });
  } catch (e) {
    print('❌ Error handling initial message: $e');
    // Fallback to menu screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => MenuScreen());
    });
  }
}

// Enhanced foreground message handling with detailed categorization
void handleForegroundMessage(RemoteMessage message) {
  print('🔔 === FOREGROUND MESSAGE RECEIVED ===');
  print('🔔 Message ID: ${message.messageId}');
  print('🔔 From: ${message.from}');
  print('🔔 Category: ${message.category}');
  print('🔔 Collapse Key: ${message.collapseKey}');
  print('🔔 Content Available: ${message.contentAvailable}');
  print('🔔 Data: ${message.data}');
  print('🔔 Notification Title: ${message.notification?.title}');
  print('🔔 Notification Body: ${message.notification?.body}');
  print('🔔 Sent Time: ${message.sentTime}');
  print('🔔 Thread ID: ${message.threadId}');
  print('🔔 TTL: ${message.ttl}');
  print('📱 Processing foreground message...');
  print('📊 Message data: ${message.data}');
  print('📊 Notification: ${message.notification?.title} - ${message.notification?.body}');

  RemoteNotification? notification = message.notification;

  if (notification == null) {
    print('❌ No notification content found');
    return;
  }

  // On iOS, when foreground presentation options are enabled, the system
  // will present notifications that include a notification payload. Showing
  // a local notification here would duplicate it. Let iOS handle it.
  if (Platform.isIOS) {
    print('ℹ️ iOS foreground: system will present notification; skipping local show.');
    return;
  }

  try {
    // Always alert on Android using a dedicated alerts channel
    String channelId = 'alerts_channel';
    String channelName = 'Alerts';
    String channelDescription = 'Always alerts with sound and heads-up for Rolling Sushi.';
    Priority priority = Priority.max;
    Importance importance = Importance.max;
    
    // Keep messageType for action buttons and payload handling
    final messageType = message.data['messageType'] ?? message.data['type'];

    // Show local notification with enhanced details
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
          // Add action buttons for certain message types
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

// Get notification actions based on message type
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

// Get notification style based on message content - returns StyleInformation?
StyleInformation? _getNotificationStyle(RemoteMessage message) {
  // You can customize notification styles here based on message content
  // For example, big text style for longer messages
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

// Enhanced message handling when app is opened from background
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
          // Navigate to order tracking
          // Get.to(() => OrderTrackingScreen(orderId: orderId));
          print('🎯 Would navigate to order tracking: $orderId');
        } else {
          Get.offAll(() => MenuScreen());
        }
        break;
        
      case 'promocode':
      case 'newPromotion':
        // Handle promocode notification
        try {
          final promocodeStore = Get.find<PromocodeStore>();
          final promocodeId = message.data['promocode_id'];
          
          if (promocodeId != null) {
            // Navigate to specific promocode
            // Get.to(() => PromocodeDetailScreen(promocodeId: promocodeId));
            print('🎯 Would navigate to promocode: $promocodeId');
          } else {
            // Show promocodes screen or main menu
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

// Enhanced notification tap handling
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
        // Default navigation to menu
        Get.offAll(() => MenuScreen());
        break;
    }
  } catch (e) {
    print('❌ Error processing notification tap: $e');
    // Fallback to menu screen
    Get.offAll(() => MenuScreen());
  }
}

// App lifecycle handler for token management
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
      // Refresh token if needed
      await _refreshTokenIfNeeded();
      
      // Check topic subscriptions
      await _checkTopicSubscriptions();
      
      // Refresh app data
      _refreshAppData();
    } catch (e) {
      print('❌ Error handling app resumed: $e');
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRegistration = prefs.getInt('token_registered_at');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Refresh token if it's been more than 24 hours
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
      
      // Re-subscribe if it's been more than 7 days
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
      // Refresh promocode data or any other app data
      print('🔄 Refreshing app data');
    } catch (e) {
      print('❌ Error refreshing app data: $e');
    }
  }

  Future<void> _handleAppDetached() async {
    try {
      // Perform any necessary cleanup
      print('🧹 Performing app cleanup');
      
      // You might want to unregister token or perform other cleanup
      // depending on your app's requirements
    } catch (e) {
      print('❌ Error during app detach cleanup: $e');
    }
  }
}

// Global SafeArea wrapper
class GlobalSafeAreaWrapper extends StatelessWidget {
  final Widget child;
  
  const GlobalSafeAreaWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Padding(
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
    
    // Initialize lifecycle handler
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
    // Additional app lifecycle handling if needed
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
            appBarTheme: const AppBarTheme(
              backgroundColor: cWhite,        // ✅ Changed from Color(0xff004032)
              foregroundColor: Color(0xff004032),   // ✅ Changed from Colors.white
              elevation: 0,
              iconTheme: IconThemeData(
                color: Color(0xff004032),           // ✅ Added green icons
              ),
            titleTextStyle: TextStyle(
              color: Color(0xff004032),           // ✅ Added green title
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
    
    // Handle language change for FCM
    if (locale != null) {
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
            // FIXED: Safe checking of setup completion
            bool isSetupComplete = false;
            try {
              // Check if language is available
              final isLanguageSet = Language.isLanguageAvailable();
              
              // Check if user is subscribed
              final isUserSubscribed = Maillinglist.isUserSubscribed();
              
              isSetupComplete = isLanguageSet && isUserSubscribed;
              
              print('🔍 Setup status - Language: $isLanguageSet, Subscribed: $isUserSubscribed, Complete: $isSetupComplete');
            } catch (e) {
              print('⚠️ Error checking setup completion: $e');
              isSetupComplete = false;
            }

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
                  print('🎬 Lottie animation loaded');
                },
              ),
            ),
            SizedBox(height: 20.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20.h),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
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
      
      // Simulate update check delay
      await Future.delayed(const Duration(seconds: 2));
      
      // You can implement actual update checking logic here
      // For example, checking version from your server or app store
      
      print('✅ Update check completed');
      return true;
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return true; // Return true to continue app initialization even if update check fails
    }
  }

  static Future<bool> isUpdateExist() async {
    try {
      // Implement your update existence check logic here
      return await checkForUpdates();
    } catch (e) {
      print('❌ Error checking if update exists: $e');
      return false;
    }
  }
}

import 'package:hive/hive.dart';

class Maillinglist {
  static const String _boxName = "maillinglist";
  static const String _subscriptionKey = "maillinglist";
  static const String _subscriptionDateKey = "subscription_date";
  static const String _fcmTokenKey = "fcm_token";
  static const String _lastUpdateKey = "last_update";

  // Get box safely with error handling
  static Box? _getBox() {
    try {
      return Hive.box(_boxName);
    } catch (e) {
      print('❌ Error getting mailing list box: $e');
      return null;
    }
  }

  // Check if box is available
  static bool _isBoxAvailable() {
    try {
      final box = Hive.box(_boxName);
      return box.isOpen;
    } catch (e) {
      print('❌ Mailing list box is not available: $e');
      return false;
    }
  }

  // FIXED: Enhanced subscribe with proper subscription management
  static bool subscribe(String subscriptionType) {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box');
        return false;
      }

      box.put(_subscriptionKey, subscriptionType);
      box.put(_subscriptionDateKey, DateTime.now().millisecondsSinceEpoch);
      box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ User subscribed to mailing list: $subscriptionType');
      return true;
    } catch (e) {
      print('❌ Error subscribing to mailing list: $e');
      return false;
    }
  }

  // FIXED: Enhanced isUserSubscribed with proper validation
  static bool isUserSubscribed() {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box');
        return false;
      }

      // Check if we have subscription data
      final subscription = box.get(_subscriptionKey);
      final isSubscribed = subscription != null;
      
      print('📧 User subscription status: $isSubscribed (value: $subscription)');
      return isSubscribed;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return false;
    }
  }

  // FIXED: Enhanced getSubscription with fallback
  static String getSubscription() {
    try {
      if (!_isBoxAvailable()) {
        print('⚠️ Mailing list box not available');
        return '';
      }

      final box = _getBox();
      if (box == null) {
        print('⚠️ Could not get mailing list box');
        return '';
      }

      final subscription = box.get(_subscriptionKey, defaultValue: '');
      print('📧 Retrieved subscription: $subscription');
      return subscription as String;
    } catch (e) {
      print('❌ Error getting subscription: $e');
      return '';
    }
  }

  // Enhanced clear with error handling
  static bool clear() {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available for clearing');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box for clearing');
        return false;
      }

      box.clear();
      print('✅ Mailing list box cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing mailing list box: $e');
      return false;
    }
  }

  // NEW: Subscribe user with default subscription
  static bool subscribeUser([String subscriptionType = 'notifications']) {
    return subscribe(subscriptionType);
  }

  // NEW: Unsubscribe user
  static bool unsubscribeUser() {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box');
        return false;
      }

      box.delete(_subscriptionKey);
      box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ User unsubscribed from mailing list');
      return true;
    } catch (e) {
      print('❌ Error unsubscribing from mailing list: $e');
      return false;
    }
  }

  // NEW: Get subscription date
  static DateTime? getSubscriptionDate() {
    try {
      if (!_isBoxAvailable()) {
        return null;
      }

      final box = _getBox();
      if (box == null) {
        return null;
      }

      final timestamp = box.get(_subscriptionDateKey);
      if (timestamp != null && timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('❌ Error getting subscription date: $e');
      return null;
    }
  }

  // NEW: Store FCM token
  static bool storeFCMToken(String token) {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box');
        return false;
      }

      box.put(_fcmTokenKey, token);
      box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ FCM token stored: ${token.substring(0, 20)}...');
      return true;
    } catch (e) {
      print('❌ Error storing FCM token: $e');
      return false;
    }
  }

  // NEW: Get stored FCM token
  static String? getFCMToken() {
    try {
      if (!_isBoxAvailable()) {
        return null;
      }

      final box = _getBox();
      if (box == null) {
        return null;
      }

      return box.get(_fcmTokenKey) as String?;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // NEW: Get last update timestamp
  static DateTime? getLastUpdate() {
    try {
      if (!_isBoxAvailable()) {
        return null;
      }

      final box = _getBox();
      if (box == null) {
        return null;
      }

      final timestamp = box.get(_lastUpdateKey);
      if (timestamp != null && timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('❌ Error getting last update: $e');
      return null;
    }
  }

  // NEW: Initialize mailing list
  static bool initializeMailingList({bool defaultSubscription = true}) {
    try {
      if (!isUserSubscribed() && defaultSubscription) {
        print('🔧 Initializing mailing list with default subscription');
        return subscribeUser();
      } else if (isUserSubscribed()) {
        print('✅ Mailing list already initialized');
        return true;
      } else {
        print('📧 Mailing list initialized without subscription');
        return true;
      }
    } catch (e) {
      print('❌ Error initializing mailing list: $e');
      return false;
    }
  }

  // NEW: Get mailing list info for debugging
  static Map<String, dynamic> getMailingListInfo() {
    try {
      return {
        'isSubscribed': isUserSubscribed(),
        'subscription': getSubscription(),
        'subscriptionDate': getSubscriptionDate()?.toIso8601String(),
        'fcmToken': getFCMToken()?.substring(0, 20),
        'lastUpdate': getLastUpdate()?.toIso8601String(),
        'boxAvailable': _isBoxAvailable(),
      };
    } catch (e) {
      return {
        'isSubscribed': false,
        'subscription': '',
        'subscriptionDate': null,
        'fcmToken': null,
        'lastUpdate': null,
        'boxAvailable': false,
        'error': e.toString(),
      };
    }
  }

  // NEW: Update subscription preferences
  static bool updateSubscriptionPreferences({
    bool? notifications = true,
    bool? promotions = true,
    bool? orderUpdates = true,
  }) {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Mailing list box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get mailing list box');
        return false;
      }

      if (notifications != null) {
        box.put('notifications_enabled', notifications);
      }
      if (promotions != null) {
        box.put('promotions_enabled', promotions);
      }
      if (orderUpdates != null) {
        box.put('order_updates_enabled', orderUpdates);
      }

      box.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Subscription preferences updated');
      return true;
    } catch (e) {
      print('❌ Error updating subscription preferences: $e');
      return false;
    }
  }

  // NEW: Get subscription preferences
  static Map<String, bool> getSubscriptionPreferences() {
    try {
      if (!_isBoxAvailable()) {
        return {
          'notifications': true,
          'promotions': true,
          'orderUpdates': true,
        };
      }

      final box = _getBox();
      if (box == null) {
        return {
          'notifications': true,
          'promotions': true,
          'orderUpdates': true,
        };
      }

      return {
        'notifications': box.get('notifications_enabled', defaultValue: true) as bool,
        'promotions': box.get('promotions_enabled', defaultValue: true) as bool,
        'orderUpdates': box.get('order_updates_enabled', defaultValue: true) as bool,
      };
    } catch (e) {
      print('❌ Error getting subscription preferences: $e');
      return {
        'notifications': true,
        'promotions': true,
        'orderUpdates': true,
      };
    }
  }
}
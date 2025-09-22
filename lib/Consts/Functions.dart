import 'dart:math';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import '../Backend/Api.dart';
import '../LocalMemory/Language.dart';
import '../LocalMemory/MemoryCoolDown.dart';

Future<void> cVibration() {
  return HapticFeedback.heavyImpact();
}

String cGenerateRandomNumbers() {
  final random = Random();
  String result = '';
  for (int i = 0; i < 4; i++) {
    result += (random.nextInt(9 - 1 + 1) + 1).toString();
  }
  return result;
}

Future<void> userUpDateGroupe() async {
  try {
    print('Starting client order count update...');
    
    // Get current order length
    String currentLengthStr = await Api.getOrderLengthPoster();
    
    // Handle case where it returns error message
    if (currentLengthStr == "Some thing went wrong") {
      print('Error getting current order length, defaulting to 0');
      currentLengthStr = "0";
    }
    
    // Parse current length and increment by 1
    int currentLength = int.tryParse(currentLengthStr) ?? 0;
    int newLength = currentLength + 1;
    
    print('Incrementing order length from $currentLength to $newLength');
    
    // Update the order length
    await Api.setOrderLengthPoster(newLength.toString());
    
    print('Successfully updated client order length to $newLength');
    
    // Update client group based on order count (optional - adjust based on your business logic)
    if (newLength >= 5 && newLength < 10) {
      await Api.updateGroupsIdUser(2); // Silver tier
      print('Updated client to Silver tier (group 2)');
    } else if (newLength >= 10 && newLength < 20) {
      await Api.updateGroupsIdUser(3); // Gold tier  
      print('Updated client to Gold tier (group 3)');
    } else if (newLength >= 20) {
      await Api.updateGroupsIdUser(4); // Platinum tier
      print('Updated client to Platinum tier (group 4)');
    }
    
  } catch (e) {
    print('Error updating client order count: $e');
    // Don't throw the error to avoid breaking the order completion flow
  }
}

String splitText(String text) {
  // Split the input text by the separator ***
  List<String> parts = text.split('***');

  print(parts);

  if (parts.length < 2) {
    return parts[0];
  } else {
    if (Language.getLanguage() == 'ru') {
      return parts[0];
    } else if (Language.getLanguage() == 'uz') {
      return parts[1];
    } else if (Language.getLanguage() == 'en') {
      return parts[2];
    }
  }

  //chaech the

  return "no text";
}

String splitTextFromCategory(String text) {
  // Split the input text by the separator ***
  List<String> parts = text.split('***');

  print(text);
  print(parts);

  if (parts.length < 2) {
    return parts[0];
  } else {
    if (Language.getLanguage() == 'ru') {
      return parts[3];
    } else if (Language.getLanguage() == 'uz') {
      return parts[4];
    } else if (Language.getLanguage() == 'en') {
      return parts[5];
    }
  }

  //chaech the

  return "no text";
}

String transformDate(String date) {
  // Split the date by the slash
  List<String> parts = date.split('/');

  // Reverse the parts and join them
  String transformedDate = parts.reversed.join('');

  return transformedDate;
}

String makePriceSomString(int price) {
  if (price <= 0) {
    return '0';
  }

  String numberStrTrimmed = price.toString();

  // If the number has fewer than 4 digits, just return it as it is
  if (numberStrTrimmed.length <= 3) {
    return numberStrTrimmed;
  }

  // Otherwise, add a space before the last three digits
  String result = numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
      " " +
      numberStrTrimmed.substring(numberStrTrimmed.length - 3);

  return result;
}

List<String> getGendersForLanguage(String languageCode) {
  switch (languageCode) {
    case 'en': // English
      return ['Other', 'Male', 'Female'];
    case 'ru': // Russian
      return ['Другой', 'Мужчина', 'Женщина'];
    case 'uz': // Uzbek
      return ['Boshqa', 'Erkak', 'Ayol'];
    default: // Default case for unsupported languages
      return ['Unknown', 'Unknown', 'Unknown'];
  }
}

bool canUpdateProfile() {
  const int maxChanges = 2;
  const int cooldownHours = 24;

  if (!Memorycooldown.isCoolDownExists()) {
    // First-time change
    Memorycooldown.setDate(DateTime.now().toString());
    Memorycooldown.setChangeCount(1);
    return true;
  } else {
    String date = Memorycooldown.getDate()!;
    DateTime lastUpdate = DateTime.parse(date);
    DateTime now = DateTime.now();

    if (now.difference(lastUpdate).inHours >= cooldownHours) {
      // Reset cooldown and allow change
      Memorycooldown.setDate(now.toString());
      Memorycooldown.setChangeCount(1); // Reset count
      return true;
    } else {
      int changeCount = Memorycooldown.getChangeCount();
      if (changeCount < maxChanges) {
        // Allow another change within the cooldown
        Memorycooldown.incrementChangeCount();
        return true;
      } else {
        // Limit reached
        return false;
      }
    }
  }
}

Future<void> unsubscribeFromAllTopics() async {
  List<String> topics = [
    'all_users_en',
    'all_users_ru',
    'all_users_uz',
    'all_users'
  ];
  for (String topic in topics) {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      print('Unsubscribed from $topic');
    } catch (e) {
      print('Error unsubscribing from $topic: $e');
    }
  }
}

Future subscribeToMailList() async {

  print("Hello Woreld");
  await FirebaseMessaging.instance.subscribeToTopic("some");
  print("subscribed to topic");

  // if (Language.isLanguageAvailable()) {
  //   String language = Language.getLanguage();
  //   if (language == "en") {
  //     unsubscribeFromAllTopics();
  //     await FirebaseMessaging.instance.subscribeToTopic("all_users_en");
  //     print("Subscribed to topic: allusers_en");
  //   } else if (language == "ru") {
  //     unsubscribeFromAllTopics();
  //     await FirebaseMessaging.instance.subscribeToTopic("all_users_ru");
  //     print("Subscribed to topic: allusers_ru");
  //   } else if (language == "uz") {
  //     unsubscribeFromAllTopics();
  //     await FirebaseMessaging.instance.subscribeToTopic("all_users_uz");
  //     print("Subscribed to topic: allusers_uz");
  //   }
  // } else {
  //   await FirebaseMessaging.instance.subscribeToTopic("all_users");
  // }
}

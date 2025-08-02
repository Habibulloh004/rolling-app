import 'dart:math';

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
  // local cehch orders

  String lengthString = await Api.getOrderLengthPoster();

  print("--------------------");
  print(lengthString);
  if (lengthString == "Some thing went wrong") {
  } else {
    int length = int.parse(lengthString) + 1;
    //Order starts from zero

    print("Number of order length ${length}");

    if (length <= 4) {
      Api.updateGroupsIdUser(5);
    } else if (length >= 5 && length <= 9) {
      Api.updateGroupsIdUser(3);
    } else if (length >= 10) {
      Api.updateGroupsIdUser(4);
    }

    print(length);
    Api.setOrderLengthPoster(length.toString());
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

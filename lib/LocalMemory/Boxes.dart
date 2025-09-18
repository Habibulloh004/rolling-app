import 'package:hive/hive.dart';
import 'package:sushi_alpha_project/LocalMemory/Bonus.dart';
import 'package:sushi_alpha_project/LocalMemory/Favorits.dart';
import 'package:sushi_alpha_project/LocalMemory/HistoryOrder.dart';
import 'package:sushi_alpha_project/LocalMemory/Language.dart';
import 'package:sushi_alpha_project/LocalMemory/Location.dart';
import 'package:sushi_alpha_project/LocalMemory/MaillingList.dart';
import 'package:sushi_alpha_project/LocalMemory/Order.dart';

import 'CreditCard.dart';
import 'MemoryCoolDown.dart';
import 'User.dart';

void initBoxes() async {
  var boxFavorites = await Hive.openBox("favorites");
  var boxOrder = await Hive.openBox("order");
  var boxMaps = await Hive.openBox("map");
  var box = await Hive.openBox("user");
  var boxHistoryOrder = await Hive.openBox("historyOrder");
  var boxBonus = await Hive.openBox("bonus");
  var boxCreditCard = await Hive.openBox("creditCard");
  var boxLanguage = await Hive.openBox("language");
  var boxUpdate = await Hive.openBox("update");
  var boxMemorycooldown = await Hive.openBox("memorycooldown");
  var boxMailingList = await Hive.openBox("maillinglist");

  // Add the promocode state box
  var boxPromocodeState = await Hive.openBox("promocode_state");
}

void clearBoxes() {
  Favorites.clean();
  MapLocation.clean();
  Order.clearOrder();
  User.clear();
  Bonus.clean();
  HistoryOrder.clear();
  CreditCard.clear();
  Language.clear();
  Memorycooldown.clean();
  Maillinglist.clear();

  // Clear promocode state as well
  try {
    Hive.box("promocode_state").clear();
  } catch (e) {
    print('Error clearing promocode state: $e');
  }
}
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

// FIXED: Changed from void to Future<void> and added proper error handling
Future<void> initBoxes() async {
  try {
    print('📦 Initializing Hive boxes...');
    
    // Open all boxes with error handling for each
    var boxFavorites = await Hive.openBox("favorites");
    print('✅ Favorites box opened');
    
    var boxOrder = await Hive.openBox("order");
    print('✅ Order box opened');
    
    var boxMaps = await Hive.openBox("map");
    print('✅ Map box opened');
    
    var box = await Hive.openBox("user");
    print('✅ User box opened');
    
    var boxHistoryOrder = await Hive.openBox("historyOrder");
    print('✅ History order box opened');
    
    var boxBonus = await Hive.openBox("bonus");
    print('✅ Bonus box opened');
    
    var boxCreditCard = await Hive.openBox("creditCard");
    print('✅ Credit card box opened');
    
    var boxLanguage = await Hive.openBox("language");
    print('✅ Language box opened');
    
    var boxUpdate = await Hive.openBox("update");
    print('✅ Update box opened');
    
    var boxMemorycooldown = await Hive.openBox("memorycooldown");
    print('✅ Memory cooldown box opened');
    
    var boxMailingList = await Hive.openBox("maillinglist");
    print('✅ Mailing list box opened');

    // Add the promocode state box
    var boxPromocodeState = await Hive.openBox("promocode_state");
    print('✅ Promocode state box opened');
    
    print('✅ All Hive boxes initialized successfully');
    
  } catch (e) {
    print('❌ Error initializing Hive boxes: $e');
    
    // Try to open boxes individually with fallbacks
    await _initBoxesWithFallback();
  }
}

// Fallback initialization for individual boxes
Future<void> _initBoxesWithFallback() async {
  final List<String> boxNames = [
    "favorites",
    "order", 
    "map",
    "user",
    "historyOrder",
    "bonus",
    "creditCard",
    "language",
    "update",
    "memorycooldown",
    "maillinglist",
    "promocode_state"
  ];
  
  for (String boxName in boxNames) {
    try {
      await Hive.openBox(boxName);
      print('✅ $boxName box opened (fallback)');
    } catch (e) {
      print('❌ Failed to open $boxName box: $e');
      
      // Create empty fallback box
      try {
        await Hive.openBox("${boxName}_fallback");
        print('⚠️ Created fallback box for $boxName');
      } catch (fallbackError) {
        print('❌ Failed to create fallback for $boxName: $fallbackError');
      }
    }
  }
}

void clearBoxes() {
  try {
    print('🧹 Clearing all boxes...');
    
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
      print('✅ Promocode state cleared');
    } catch (e) {
      print('❌ Error clearing promocode state: $e');
    }
    
    print('✅ All boxes cleared successfully');
    
  } catch (e) {
    print('❌ Error clearing boxes: $e');
  }
}

// Helper function to check if a box is available
bool isBoxAvailable(String boxName) {
  try {
    final box = Hive.box(boxName);
    return box.isOpen;
  } catch (e) {
    print('❌ Box $boxName is not available: $e');
    return false;
  }
}

// Get box safely with error handling
Box? getBoxSafe(String boxName) {
  try {
    return Hive.box(boxName);
  } catch (e) {
    print('❌ Error getting box $boxName: $e');
    return null;
  }
}
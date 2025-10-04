import 'package:hive/hive.dart';

class Language {
  static const String _boxName = "language";
  static const String _languageKey = "language";
  static const String _defaultLanguage = "ru";
  static const List<String> _supportedLanguages = ['en', 'uz', 'ru'];

  // Get box safely with error handling
  static Box? _getBox() {
    try {
      return Hive.box(_boxName);
    } catch (e) {
      print('❌ Error getting language box: $e');
      return null;
    }
  }

  // Check if box is available
  static bool _isBoxAvailable() {
    try {
      final box = Hive.box(_boxName);
      return box.isOpen;
    } catch (e) {
      print('❌ Language box is not available: $e');
      return false;
    }
  }

  // FIXED: Enhanced setLanguage with validation and error handling
  static bool setLanguage(String language) {
    try {
      // Validate language
      if (!_supportedLanguages.contains(language)) {
        print('❌ Invalid language: $language. Supported: $_supportedLanguages');
        return false;
      }

      if (!_isBoxAvailable()) {
        print('❌ Language box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get language box');
        return false;
      }

      box.put(_languageKey, language);
      print('✅ Language set to: $language');
      return true;
    } catch (e) {
      print('❌ Error setting language: $e');
      return false;
    }
  }

  // FIXED: Enhanced isLanguageAvailable with proper validation
  static bool isLanguageAvailable() {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Language box is not available');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get language box');
        return false;
      }

      // Check if we have the language key and it's a valid language
      final language = box.get(_languageKey);
      final isAvailable = language != null && 
                         language is String && 
                         _supportedLanguages.contains(language);
      
      print('📍 Language availability: $isAvailable (stored: $language)');
      return isAvailable;
    } catch (e) {
      print('❌ Error checking language availability: $e');
      return false;
    }
  }

  // FIXED: Enhanced getLanguage with fallback and validation
  static String getLanguage() {
    try {
      if (!_isBoxAvailable()) {
        print('⚠️ Language box not available, using default: $_defaultLanguage');
        return _defaultLanguage;
      }

      final box = _getBox();
      if (box == null) {
        print('⚠️ Could not get language box, using default: $_defaultLanguage');
        return _defaultLanguage;
      }

      final language = box.get(_languageKey, defaultValue: _defaultLanguage);
      
      // Validate the language
      if (language == null || !_supportedLanguages.contains(language)) {
        print('⚠️ Invalid stored language: $language, using default: $_defaultLanguage');
        // Try to set the default language
        setLanguage(_defaultLanguage);
        return _defaultLanguage;
      }

      print('📍 Retrieved language: $language');
      return language as String;
    } catch (e) {
      print('❌ Error getting language: $e, using default: $_defaultLanguage');
      return _defaultLanguage;
    }
  }

  // Enhanced clear with error handling
  static bool clear() {
    try {
      if (!_isBoxAvailable()) {
        print('❌ Language box is not available for clearing');
        return false;
      }

      final box = _getBox();
      if (box == null) {
        print('❌ Could not get language box for clearing');
        return false;
      }

      box.clear();
      print('✅ Language box cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing language box: $e');
      return false;
    }
  }

  // NEW: Initialize language with default if not set
  static bool initializeLanguage([String? initialLanguage]) {
    try {
      final currentLanguage = initialLanguage ?? _defaultLanguage;
      
      if (!isLanguageAvailable()) {
        print('🔧 Initializing language to: $currentLanguage');
        return setLanguage(currentLanguage);
      } else {
        print('✅ Language already initialized: ${getLanguage()}');
        return true;
      }
    } catch (e) {
      print('❌ Error initializing language: $e');
      return false;
    }
  }

  // NEW: Get supported languages
  static List<String> getSupportedLanguages() {
    return List.from(_supportedLanguages);
  }

  // NEW: Get default language
  static String getDefaultLanguage() {
    return _defaultLanguage;
  }

  // NEW: Validate language
  static bool isValidLanguage(String language) {
    return _supportedLanguages.contains(language);
  }

  // NEW: Get language info for debugging
  static Map<String, dynamic> getLanguageInfo() {
    try {
      return {
        'current': getLanguage(),
        'isSet': isLanguageAvailable(),
        'supported': _supportedLanguages,
        'default': _defaultLanguage,
        'boxAvailable': _isBoxAvailable(),
      };
    } catch (e) {
      return {
        'current': _defaultLanguage,
        'isSet': false,
        'supported': _supportedLanguages,
        'default': _defaultLanguage,
        'boxAvailable': false,
        'error': e.toString(),
      };
    }
  }
}
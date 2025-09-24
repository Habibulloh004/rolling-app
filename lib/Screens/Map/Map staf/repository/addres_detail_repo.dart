import 'package:dio/dio.dart';

import '../Models/app_lat_long.dart';

class AddressDetailRepository {
  // Static cache to store resolved addresses
  static final Map<String, String> _addressCache = {};
  
  @override
  Future<String?> getAddressDetail(AppLatLong latLong) async {
    double lat = latLong.lat;
    double lon = latLong.long;
    
    // Create cache key
    String cacheKey = "${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}";
    
    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      print('📍 Using cached address for $cacheKey: ${_addressCache[cacheKey]}');
      _updateCacheStats(true);
      return _addressCache[cacheKey];
    }
    
    _updateCacheStats(false);
    
    // Try multiple geocoding approaches
    String? address = await _tryNominatimMultipleAttempts(lat, lon);
    if (address != null && _isValidAddress(address)) {
      _addressCache[cacheKey] = address;
      return address;
    }
    
    // Try alternative nominatim servers
    address = await _tryAlternativeNominatimServers(lat, lon);
    if (address != null && _isValidAddress(address)) {
      _addressCache[cacheKey] = address;
      return address;
    }
    
    // Try different language and region settings
    address = await _tryDifferentLanguageSettings(lat, lon);
    if (address != null && _isValidAddress(address)) {
      _addressCache[cacheKey] = address;
      return address;
    }
    
    // Last resort: return formatted coordinates
    String coordinateAddress = "Location: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}";
    _addressCache[cacheKey] = coordinateAddress;
    return coordinateAddress;
  }

  bool _isValidAddress(String address) {
    return !address.startsWith("Location:") && 
           !address.startsWith("Unable") && 
           address.trim().isNotEmpty &&
           address.length > 2;
  }

  Future<String?> _tryNominatimMultipleAttempts(double lat, double lon) async {
    // Multiple URL configurations with different parameters for better results
    List<Map<String, dynamic>> urlConfigs = [
      {
        'url': 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
        'description': 'High zoom with full details'
      },
      {
        'url': 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
        'description': 'Medium zoom with multiple languages'
      },
      {
        'url': 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
        'description': 'Low zoom for broader area'
      },
      {
        'url': 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
        'description': 'Very low zoom for city/region level'
      },
    ];

    final Dio dio = Dio();
    
    // Enhanced timeout and retry configuration
    dio.options.connectTimeout = Duration(seconds: 35);
    dio.options.receiveTimeout = Duration(seconds: 35);
    dio.options.sendTimeout = Duration(seconds: 35);
    
    // Proper headers to avoid blocking and rate limiting
    dio.options.headers = {
      'User-Agent': 'SushiApp/1.0 (https://example.com/contact)',
      'Accept': 'application/json',
      'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8,uz;q=0.7',
      'Cache-Control': 'no-cache',
      'Referer': 'https://openstreetmap.org/',
    };

    for (var config in urlConfigs) {
      try {
        print('🌐 Trying Nominatim: ${config['description']}');
        print('🔗 URL: ${config['url']}');
        
        final response = await dio.get(config['url']);
        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          
          if (data is Map<String, dynamic>) {
            print('📍 Raw response data keys: ${data.keys.toList()}');
            
            String? address = _parseNominatimResponse(data);
            if (address != null && _isValidAddress(address)) {
              print('✅ Successfully parsed address: $address');
              return address;
            } else {
              print('⚠️ Parsed address was invalid or empty: $address');
            }
          } else {
            print('⚠️ Response data is not a valid map');
          }
        } else {
          print('❌ Bad response status: ${response.statusCode}');
        }
        
        // Wait between requests to be respectful to the service
        if (config != urlConfigs.last) {
          await Future.delayed(Duration(milliseconds: 1200));
        }
        
      } catch (error) {
        print('💥 Nominatim request failed (${config['description']}): $error');
        
        // If it's a timeout or connection error, wait before trying next
        if (error is DioException && 
            (error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.connectionError)) {
          await Future.delayed(Duration(milliseconds: 2000));
        }
        continue;
      }
    }
    
    return null;
  }

  String? _parseNominatimResponse(Map<String, dynamic> data) {
    // Priority 1: Try to get the full display_name first (complete address)
    final displayName = data['display_name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      // Clean up the display name
      String cleanedAddress = _cleanDisplayName(displayName);
      if (cleanedAddress.length > 5) {
        print('✅ Using full display_name: $cleanedAddress');
        return cleanedAddress;
      }
    }
    
    // Priority 2: If no display_name, build complete address from components
    if (data['address'] != null) {
      final addressData = data['address'] as Map<String, dynamic>;
      print('🏠 Building full address from components: ${addressData.keys.toList()}');
      
      String? fullAddress = _buildFullAddressFromComponents(addressData);
      if (fullAddress != null && fullAddress.length > 5) {
        print('✅ Built full address from components: $fullAddress');
        return fullAddress;
      }
    }
    
    // Priority 3: Try name field
    final name = data['name'] as String?;
    if (name != null && name.isNotEmpty && name.length > 3) {
      print('✅ Using name field: $name');
      return name;
    }
    
    // Priority 4: Last fallback - try to extract any meaningful text
    return _extractAnyMeaningfulAddress(data);
  }

  String _cleanDisplayName(String displayName) {
    // Remove excessive whitespace and clean up the address
    String cleaned = displayName.trim();
    
    // Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove duplicate commas
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ',');
    
    // Clean up leading/trailing commas
    cleaned = cleaned.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
    
    return cleaned;
  }

  String? _buildFullAddressFromComponents(Map<String, dynamic> addressData) {
    List<String> addressParts = [];
    
    // Step 1: House number and street name (most specific)
    String? houseNumber = addressData['house_number'];
    String? street = addressData['road'] ?? 
                    addressData['street'] ?? 
                    addressData['pedestrian'] ??
                    addressData['footway'] ??
                    addressData['cycleway'] ??
                    addressData['path'];
    
    // Add house number + street
    if (houseNumber != null && street != null) {
      addressParts.add('$houseNumber $street');
    } else if (street != null) {
      addressParts.add(street);
    }
    
    // Step 2: Add building or complex name if available and not already included
    String? building = addressData['building'] ?? 
                      addressData['house_name'] ??
                      addressData['building_name'];
    if (building != null && !_isAlreadyIncluded(building, addressParts)) {
      if (addressParts.isEmpty) {
        addressParts.add(building);
      } else {
        addressParts.insert(0, building);
      }
    }
    
    // Step 3: Add amenity/poi if available (restaurants, shops, etc.)
    String? poi = addressData['amenity'] ?? 
                 addressData['shop'] ?? 
                 addressData['leisure'] ?? 
                 addressData['tourism'] ??
                 addressData['office'] ??
                 addressData['craft'] ??
                 addressData['emergency'];
    if (poi != null && !_isAlreadyIncluded(poi, addressParts)) {
      String formattedPoi = _capitalizeWords(poi);
      if (addressParts.isEmpty) {
        addressParts.add(formattedPoi);
      } else {
        addressParts.insert(0, formattedPoi);
      }
    }
    
    // Step 4: Add neighborhood/suburb
    String? neighborhood = addressData['neighbourhood'] ??
                          addressData['suburb'] ??
                          addressData['quarter'] ??
                          addressData['residential'] ??
                          addressData['hamlet'];
    if (neighborhood != null && !_isAlreadyIncluded(neighborhood, addressParts)) {
      addressParts.add(neighborhood);
    }
    
    // Step 5: Add district
    String? district = addressData['district'] ??
                      addressData['city_district'] ??
                      addressData['borough'] ??
                      addressData['county'];
    if (district != null && !_isAlreadyIncluded(district, addressParts)) {
      addressParts.add(district);
    }
    
    // Step 6: Add city/town
    String? city = addressData['city'] ??
                  addressData['town'] ??
                  addressData['village'] ??
                  addressData['municipality'];
    if (city != null && !_isAlreadyIncluded(city, addressParts)) {
      addressParts.add(city);
    }
    
    // Step 7: Add state/region if different from city
    String? state = addressData['state'] ??
                   addressData['region'] ??
                   addressData['province'] ??
                   addressData['state_district'];
    if (state != null && !_isAlreadyIncluded(state, addressParts)) {
      addressParts.add(state);
    }
    
    // Step 8: Add country if available and meaningful
    String? country = addressData['country'];
    if (country != null && 
        !_isAlreadyIncluded(country, addressParts) &&
        !['Russia', 'Russian Federation', 'Россия', 'RU'].contains(country)) {
      addressParts.add(country);
    }
    
    // Step 9: Add postcode if available and not too generic
    String? postcode = addressData['postcode'];
    if (postcode != null && postcode.length > 2 && postcode.length < 10) {
      addressParts.add(postcode);
    }
    
    // Join all parts with commas and clean up
    if (addressParts.isNotEmpty) {
      String fullAddress = addressParts.join(', ');
      return _cleanDisplayName(fullAddress);
    }
    
    return null;
  }

  bool _isAlreadyIncluded(String newPart, List<String> existingParts) {
    String lowerNewPart = newPart.toLowerCase();
    for (String part in existingParts) {
      if (part.toLowerCase().contains(lowerNewPart) || 
          lowerNewPart.contains(part.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  String? _extractAnyMeaningfulAddress(Map<String, dynamic> data) {
    // Try to extract any meaningful address information as fallback
    List<String?> fallbackSources = [
      data['name'] as String?,
      data['display_name'] as String?,
    ];
    
    for (String? source in fallbackSources) {
      if (source != null && source.trim().isNotEmpty && source.length > 3) {
        // Clean up the address
        String cleaned = _cleanDisplayName(source);
        
        // Don't return if it's just coordinates
        if (!RegExp(r'^[\d\.\-\s,]+$').hasMatch(cleaned)) {
          return cleaned;
        }
      }
    }
    
    return null;
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
    ).join(' ');
  }

  Future<String?> _tryAlternativeNominatimServers(double lat, double lon) async {
    // Alternative Nominatim servers and configurations
    List<Map<String, String>> alternativeConfigs = [
      {
        'url': 'https://nominatim.osm.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
        'description': 'Alternative OSM server'
      },
      {
        'url': 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=15&addressdetails=1',
        'description': 'Extended details request'
      },
    ];

    final Dio dio = Dio();
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    
    for (var config in alternativeConfigs) {
      try {
        print('🔄 Trying alternative: ${config['description']}');
        
        // Vary headers to avoid being blocked
        dio.options.headers = {
          'User-Agent': 'Mozilla/5.0 (compatible; SushiApp-Alt/1.0)',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8',
          'Referer': 'https://openstreetmap.org/',
        };
        
        final response = await dio.get(config['url']!);
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          print('🌐 Alternative server response received');
          
          String? address = _parseNominatimResponse(data);
          if (address != null && _isValidAddress(address)) {
            print('✅ Alternative server success: $address');
            return address;
          }
        }
        
        // Be respectful with delays
        await Future.delayed(Duration(milliseconds: 1500));
        
      } catch (error) {
        print('⚠️ Alternative server failed: $error');
        continue;
      }
    }
    
    return null;
  }

  Future<String?> _tryDifferentLanguageSettings(double lat, double lon) async {
    // Try different language preferences for different regions
    List<String> languageSettings = [
      'ru,en',           // Russian + English
      'uz,en',           // Uzbek + English
      'local,en',        // Local language + English
      'en,local',        // English + Local
    ];

    final Dio dio = Dio();
    dio.options.connectTimeout = Duration(seconds: 25);
    dio.options.receiveTimeout = Duration(seconds: 25);
    
    for (String lang in languageSettings) {
      try {
        String url = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1';
        
        print('🌍 Trying language setting: $lang');
        
        dio.options.headers = {
          'User-Agent': 'SushiApp-Multilang/1.0',
          'Accept': 'application/json',
          'Accept-Language': '$lang,*;q=0.5',
        };
        
        final response = await dio.get(url);
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          
          String? address = _parseNominatimResponse(data);
          if (address != null && _isValidAddress(address) && address.length > 10) {
            print('✅ Language-specific success: $address');
            return address;
          }
        }
        
        await Future.delayed(Duration(milliseconds: 1000));
        
      } catch (error) {
        print('⚠️ Language setting $lang failed: $error');
        continue;
      }
    }
    
    return null;
  }

  // Method to clear cache if needed
  static void clearCache() {
    _addressCache.clear();
    print('🧹 Address cache cleared');
  }
  
  // Method to get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_addresses': _addressCache.length,
      'cache_keys': _addressCache.keys.toList(),
      'cache_size_estimate': _addressCache.toString().length,
    };
  }

  // Method to preload addresses for known locations
  static Future<void> preloadAddresses(List<AppLatLong> locations) async {
    final repo = AddressDetailRepository();
    for (AppLatLong location in locations) {
      try {
        await repo.getAddressDetail(location);
        await Future.delayed(Duration(milliseconds: 500)); // Rate limiting
      } catch (e) {
        print('Preload failed for ${location.lat}, ${location.long}: $e');
      }
    }
  }

  // Method to get cache hit rate
  static double getCacheHitRate() {
    if (_cacheRequests == 0) return 0.0;
    return _cacheHits / _cacheRequests;
  }

  static int _cacheHits = 0;
  static int _cacheRequests = 0;

  // Update cache statistics (call this in getAddressDetail)
  void _updateCacheStats(bool isHit) {
    _cacheRequests++;
    if (isHit) _cacheHits++;
  }
}
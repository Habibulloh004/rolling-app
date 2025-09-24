import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/LocalMemory/Location.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';
import 'package:sushi_alpha_project/Screens/Order/PaymentAndLocation.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';
import 'Map staf/Models/app_lat_long.dart';
import 'Map staf/repository/addres_detail_repo.dart';
import 'Map staf/service/app_location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Map action;
  double currentLat = 55.7522200; // Default to Moscow
  double currentLon = 37.6155600; // Default to Moscow
  double zoomLevel = 18;
  late YandexMapController _yandexMapController;
  final mapControllerCompleter = Completer<YandexMapController>();
  String addressDetail = "Map Page";
  final AddressDetailRepository repository = AddressDetailRepository();
  bool isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _initPermission().ignore();
    AndroidYandexMap.useAndroidViewSurface = false;
    action = Get.arguments;
  }

  // Helper methods for address formatting in UI
  String _getShortAddress(String fullAddress) {
    if (fullAddress.length <= 40) return fullAddress;
    
    // For long addresses, show the first part
    List<String> parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      String firstPart = parts.first.trim();
      if (firstPart.length > 40) {
        return firstPart.substring(0, 37) + "...";
      }
      
      // If first part is short, try to add second part
      if (parts.length > 1 && firstPart.length < 25) {
        String secondPart = parts[1].trim();
        String combined = "$firstPart, $secondPart";
        if (combined.length <= 40) {
          return combined;
        } else {
          return firstPart;
        }
      }
      
      return firstPart;
    }
    
    return fullAddress.substring(0, 37) + "...";
  }
  
  String _getSecondLine(String fullAddress) {
    String shortAddress = _getShortAddress(fullAddress);
    
    // If the short address is the same as full, no second line needed
    if (shortAddress == fullAddress) return "";
    
    // Extract remaining part after the short address
    List<String> parts = fullAddress.split(',');
    if (parts.length > 1) {
      // Find where the short address ends
      int startIndex = 1;
      if (shortAddress.contains(',')) {
        // Short address contains multiple parts
        int commaCount = ','.allMatches(shortAddress).length;
        startIndex = commaCount + 1;
      }
      
      if (startIndex < parts.length) {
        String remaining = parts.skip(startIndex).join(', ').trim();
        if (remaining.isNotEmpty && remaining.length > 3) {
          if (remaining.length > 50) {
            return remaining.substring(0, 47) + "...";
          }
          return remaining;
        }
      }
    }
    
    return "";
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cDarkGreen,
        title: Row(
          children: [
            if (isLoadingAddress)
              Container(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: cWhite,
                  strokeWidth: 2,
                ),
              ),
            if (isLoadingAddress) SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getShortAddress(addressDetail),
                    style: TextStyle(
                      color: cWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (_getShortAddress(addressDetail) != addressDetail &&
                      addressDetail.length > 40) ...[
                    SizedBox(height: 2),
                    Text(
                      _getSecondLine(addressDetail),
                      style: TextStyle(
                        color: cWhite.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.navigate_before,
            color: cWhite,
            size: 30,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "current_location",
        onPressed: () {
          _fetchCurrentLocation();
        },
        backgroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.my_location, color: cDarkGreen),
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              mapControllerCompleter.complete(controller);
              _yandexMapController = controller;
            },
            onCameraPositionChanged: (cameraPosition, reason, finished) {
              if (finished) {
                updateAddressDetail(AppLatLong(
                    lat: cameraPosition.target.latitude,
                    long: cameraPosition.target.longitude));
                currentLat = cameraPosition.target.latitude;
                currentLon = cameraPosition.target.longitude;
              }
            },
          ),
          // Centered location pin
          const Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
          // Zoom controls
          Positioned(
            bottom: size.height * 0.25,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  onPressed: () {
                    addZoom();
                  },
                  backgroundColor: Colors.white,
                  elevation: 2,
                  mini: true,
                  child: const Icon(Icons.add, color: cDarkGreen),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  onPressed: () {
                    removeZoom();
                  },
                  backgroundColor: Colors.white,
                  elevation: 2,
                  mini: true,
                  child: const Icon(Icons.remove, color: cDarkGreen),
                ),
              ],
            )
          ),
          // Confirm button
          Positioned(
            bottom: size.height * 0.05,
            left: size.width * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: size.height * 0.07,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                onPressed: isLoadingAddress 
                    ? null 
                    : () {
                  // Allow confirmation as long as we're not loading and have address info
                  if (!isLoadingAddress && addressDetail != "Map Page" && 
                      !addressDetail.contains("...resolving")) {
                    print("****************");
                    print("Action: ${action['action']}");
                    print("Is no maps: ${MapLocation.isNoMaps()}");
                    print("Address: $addressDetail");
                    
                    // Only handle add action now
                    if (action['action'] == 'add' && MapLocation.isNoMaps()) {
                      print("------Adding first location---------");
                      Map data = {
                        'name': addressDetail,
                        'shortName': _getShortAddress(addressDetail),
                        'lat': currentLat,
                        'lon': currentLon,
                      };
                      MapLocation.addLocation(data);
                      
                      //checking the length of how many they have
                      //order check
                      if (Order.isNoOrder()) {
                        Get.offAll(() => MenuScreen());
                      } else {
                        Get.off(() => PaymentAndLocationScreen());
                      }
                    } else if (action['action'] == 'add') {
                      Map data = {
                        'name': addressDetail,
                        'shortName': _getShortAddress(addressDetail),
                        'lat': currentLat,
                        'lon': currentLon,
                      };
                      MapLocation.addLocation(data);
                      Get.back();
                    }
                  }
                },
                child: isLoadingAddress 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Loading...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "${LocaleData.confirm.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          )
        ],
      ),
    );
  }

  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    
    // Get current location
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    AppLatLong location;
    const defLocation = MoscowLocation();
    try {
      location = await LocationService().getCurrentLocation();
      print('✅ Got current location: ${location.lat}, ${location.long}');
    } catch (e) {
      print('❌ Failed to get current location: $e');
      location = defLocation;
    }
    updateAddressDetail(location);
    currentLat = location.lat;
    currentLon = location.long;
    _moveToCurrentLocation(location);
  }

  Future<void> _moveToCurrentLocation(AppLatLong appLatLong) async {
    try {
      (await mapControllerCompleter.future).moveCamera(
        animation: const MapAnimation(type: MapAnimationType.linear, duration: 1),
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
              latitude: appLatLong.lat,
              longitude: appLatLong.long,
            ),
            zoom: zoomLevel,
          ),
        ),
      );
    } catch (e) {
      print('Error moving camera: $e');
    }
  }

  Future<void> updateAddressDetail(AppLatLong latLong) async {
    setState(() {
      addressDetail = "...resolving address";
      isLoadingAddress = true;
    });
    
    // Add 0.5 second delay before resolving address
    await Future.delayed(Duration(milliseconds: 500));
    
    try {
      print('🔍 Starting address resolution for: ${latLong.lat}, ${latLong.long}');
      String? data = await repository.getAddressDetail(latLong);
      
      setState(() {
        if (data != null && data.isNotEmpty) {
          addressDetail = data;
          print('✅ Address resolved successfully: $data');
        } else {
          addressDetail = "Unable to resolve address";
          print('❌ Geocoding returned empty result');
        }
        isLoadingAddress = false;
      });
      
    } catch (e) {
      setState(() {
        addressDetail = "Address resolution failed";
        isLoadingAddress = false;
      });
      print('💥 Error during address resolution: $e');
    }
  }

  void addZoom() {
    if (_yandexMapController != null && zoomLevel < 21) {
      zoomLevel += 1;
      _yandexMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: currentLat, longitude: currentLon),
            zoom: zoomLevel,
          ),
        ),
      );
    }
  }

  void removeZoom() {
    if (_yandexMapController != null && zoomLevel > 1) {
      zoomLevel -= 1;
      _yandexMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: currentLat, longitude: currentLon),
            zoom: zoomLevel,
          ),
        ),
      );
    }
  }
}
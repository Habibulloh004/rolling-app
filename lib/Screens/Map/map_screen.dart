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
  late double currentLat;
  late double currentLon;
  double zoomLevel = 18;
  late YandexMapController _yandexMapController;
  final mapControllerCompleter = Completer<YandexMapController>();
  String addressDetail = "Map Page";
  final AddressDetailRepository repository = AddressDetailRepository();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initPermission().ignore();
    AndroidYandexMap.useAndroidViewSurface = false;
    action = Get.arguments;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cDarkGreen,
        title: Text(addressDetail,
            style: TextStyle(
              color: cWhite,
            )),
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.navigate_before,
              color: cWhite,
              size: 30,
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchCurrentLocation();
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location),
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
          Positioned(
              bottom: size.height * 0.2,
              right: 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      addZoom();
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      removeZoom();
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove),
                  ),
                ],
              )),
          Positioned(
              bottom: size.height * 0.05,
              left: size.width * 0.1,
              child: Container(
                width: size.width * 0.65,
                height: size.height * 0.07,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(cDarkGreen),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Rounded corners
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (addressDetail != "...loading") {
                      print("****************");
                      print(MapLocation.isNoMaps());
                      print(action['action'] == 'add');
                      //is empty
                      if (action['action'] == 'add' && MapLocation.isNoMaps()) {
                        print("------efkekfefkk---------");
                        Map data = {
                          'name': addressDetail,
                          'lat': currentLat,
                          'lon': currentLon,
                        };
                        MapLocation.addLocation(data);
                        //cheching the lenght of how many they have
                        //order check

                        if (Order.isNoOrder()) {
                          Get.offAll(() => MenuScreen());
                        } else {
                          Get.off(() => PaymentAndLocationScreen());
                        }
                      } else if (action['action'] == 'add') {
                        Map data = {
                          'name': addressDetail,
                          'lat': currentLat,
                          'lon': currentLon,
                        };
                        MapLocation.addLocation(data);
                        Get.back();
                      } else if (action['action'] == 'edit') {
                        Map data = {
                          'name': addressDetail,
                          'lat': currentLat,
                          'lon': currentLon,
                        };
                        MapLocation.updateAt(action['id'], data);
                        Get.back();
                      }
                    }
                  },
                  child: Text("${LocaleData.confirm.getString(context)}",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ))
        ],
      ),
    );
  }

  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    AppLatLong location;
    const defLocation = MoscowLocation();
    try {
      location = await LocationService().getCurrentLocation();
    } catch (_) {
      location = defLocation;
    }
    updateAddressDetail(location);
    currentLat = location.lat;
    currentLon = location.long;
    _moveToCurrentLocation(location);
  }

  Future<void> _moveToCurrentLocation(
    AppLatLong appLatLong,
  ) async {
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
  }

  Future<void> updateAddressDetail(AppLatLong latLong) async {
    addressDetail = "...loading";
    setState(() {});
    String? data = await repository.getAddressDetail(latLong);
    // String fullAddress =
    //     data!.response!.geoObjectCollection!.featureMember!.isEmpty
    //         ? "unknowen_place"
    //         : data.response!.geoObjectCollection!.featureMember![0].geoObject!
    //             .metaDataProperty!.geocoderMetaData!.address!.formatted
    //             .toString();
    //
    // List<String> addressParts = fullAddress.split(', ');
    //
    // String county = addressParts[addressParts.length - 2];
    // String city = addressParts[addressParts.length - 1];

    addressDetail = data ?? "error";
    setState(() {});
    print(addressDetail);
  }

  addZoom() {
    if (_yandexMapController != null) {
      _yandexMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
                latitude: currentLat,
                longitude: currentLon), // Example coordinates
            zoom: zoomLevel += 1,
          ),
        ),
      );
    }
  }

  removeZoom() {
    if (_yandexMapController != null) {
      _yandexMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
                latitude: currentLat,
                longitude: currentLon), // Example coordinates
            zoom: zoomLevel -= 1,
          ),
        ),
      );
    }
  }
}

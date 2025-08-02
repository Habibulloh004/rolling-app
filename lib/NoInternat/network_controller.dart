import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();

    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    if (connectivityResult == ConnectivityResult.none) {
      // Get.offAll(() => NoInternetScreen());
      Get.rawSnackbar(
        messageText: Text("Нет соединения с интернетом",
            style: TextStyle(
              color: Colors.white,
            )),
        isDismissible: false,
        duration: Duration(days: 1),
        backgroundColor: Colors.red[400]!,
        icon: Icon(
          Icons.wifi_off,
          color: Colors.white,
          size: 35,
        ),
        margin: EdgeInsets.zero,
        snackStyle: SnackStyle.GROUNDED,
      );
    } else {
      // Get.offAll(() => MenuScreen());
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    }
  }
}

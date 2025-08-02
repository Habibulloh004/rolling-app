import 'package:get/get.dart';
import 'package:sushi_alpha_project/NoInternat/network_controller.dart';

class DependencyInjection {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
  }
}

import 'package:dio/dio.dart';

import '../Models/app_lat_long.dart';

class AddressDetailRepository {
  @override
  Future<String?> getAddressDetail(AppLatLong latLong) async {
    // String mapApiKey = "df5e799d-9029-4e90-9fa2-05f464aa297e";

    // try {
    //   Map<String, String> queryParams = {
    //     'apikey': mapApiKey,
    //     'geocode': '${latLong.long},${latLong.lat}',
    //     'lang': 'uz',
    //     'format': 'json',
    //     'results': '1',
    //   };
    //   Dio yandexDio = Dio();
    //   var response = await yandexDio.get(
    //     "https://geocode-maps.yandex.ru/1.x/",
    //     queryParameters: queryParams,

    //   );

    double lat = latLong.lat; // Latitude
    double lon = latLong.long; // Longitude
    String url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon';
    //AddressDetailModel.fromJson();

    final Dio dio = Dio();

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        print('Street: ${data["address"]["road"]}');
        print('Full Address: ${data["display_name"]}');

        return data["address"]["road"];
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
        return " ";
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }
}

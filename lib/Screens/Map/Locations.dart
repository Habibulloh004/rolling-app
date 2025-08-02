import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Location.dart';
import '../../Localzition/locals.dart';
import 'map_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cDarkGreen,
        ),
        title:
            cAppBarTittle(text: "${LocaleData.myaddresses.getString(context)}"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: cDarkGreen,
              size: 35,
            ), // Replace with an SVG if you have a specific icon
            onPressed: () {
              Get.to(MapScreen(), arguments: {'action': 'add'})?.then((value) {
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: ListView.builder(
          itemCount: MapLocation.getLength(), // 100 list items
          itemBuilder: (context, index) {
            String name = MapLocation.getLocationAt(index)['name'];
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: cDarkGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                              fontSize: 15,
                              color: cWhite,
                              fontWeight: FontWeight.w300,
                            )),
                      ),
                      Icon(
                        Icons.my_location,
                        size: 37,
                        color: cWhite,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(MapScreen(),
                                    arguments: {'action': 'edit', 'id': index});
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: cWhite,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    "${LocaleData.edit.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  MapLocation.deleteAt(index)?.then((value) {
                                    setState(() {});
                                  });
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: cWhite,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    "${LocaleData.delete.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

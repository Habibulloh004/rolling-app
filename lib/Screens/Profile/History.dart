import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/LocalMemory/HistoryOrder.dart';
import 'package:sushi_alpha_project/Screens/Profile/OrderTrack.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Widgets.dart';
import '../../Localzition/locals.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List info = HistoryOrder.getReversedHistoryOrder();

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
        title: Text("${LocaleData.historyoforders.getString(context)}",
            style: TextStyle(
              fontSize: 25,
              color: cDarkGreen,
              fontWeight: FontWeight.w700,
            )),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: ListView.builder(
          itemCount: HistoryOrder.getLength(), // 100 list items
          itemBuilder: (context, index) {
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
                  Text(
                      "${LocaleData.orderid.getString(context)}:  ${info[index]['id']} ",
                      style: TextStyle(
                        fontSize: 15,
                        color: cWhite,
                        fontWeight: FontWeight.w600,
                      )),
                  SizedBox(height: 8.h),
                  Text(
                    "${LocaleData.ordertime.getString(context)}: ${info[index]['date']}",
                    style: TextStyle(
                      fontSize: 15,
                      color: cWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${LocaleData.total.getString(context)}: ${info[index]['priceOfOrderString']}",
                          style: TextStyle(
                            fontSize: 15,
                            color: cWhite,
                            fontWeight: FontWeight.w600,
                          )),
                      GestureDetector(
                        onTap: () {
                          print(index);
                          print(info.length);
                          print((info.length - index) - 1);
                          Get.to(() => OrderTrackScreen(), arguments: {
                            'id': (info.length - index) - 1,
                            'date': info[index]['date'],
                            'sum': info[index]['priceOfOrderString'],
                            'orderId': info[index]['id'],
                            'payment_method': info[index]['payment_method'],
                            'type': info[index]['type']
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: cWhite,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:
                              Text("${LocaleData.indetail.getString(context)}",
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: cDarkGreen,
                                    fontWeight: FontWeight.w600,
                                  )),
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

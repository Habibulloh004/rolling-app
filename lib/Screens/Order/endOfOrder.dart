import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Consts/Colors.dart';
import '../../LocalMemory/Bonus.dart';
import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';

class EndOFOrderScreen extends StatefulWidget {
  const EndOFOrderScreen({super.key});

  @override
  State<EndOFOrderScreen> createState() => _EndOFOrderScreenState();
}

class _EndOFOrderScreenState extends State<EndOFOrderScreen> {
  Map info = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 40.h,
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        textAlign: TextAlign.center,
                        "${LocaleData.thankyouforchoosingus1.getString(context)} \n ${LocaleData.thankyouforchoosingus2.getString(context)}",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
                Container(
                  width: 134.w,
                  height: 161.h,
                  child: Image.asset(
                    "assets/images/HuginSushi.png",
                    // fit: BoxFit.cover,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: cDarkGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  children: [
                    SizedBox(
                      height: 28.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("${LocaleData.orderconfirmed.getString(context)}:",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                    SizedBox(
                      height: 24.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${LocaleData.products.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            )),
                        Text(
                            "${Order.getOrderPrice()['string']} ${LocaleData.som.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${LocaleData.delivery.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            )),
                        Text(
                            info['orderType'] == "delivery"
                                ? "${info['deliveryPrice']} ${LocaleData.som.getString(context)}"
                                : "0 ${LocaleData.som.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            info['discount']
                                ? "${LocaleData.bonuslowercase.getString(context)}"
                                : "${LocaleData.bonuslowercase.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            )),
                        Text(info['bonus'],
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${LocaleData.total.getString(context)}:",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            )),
                        Text(info['itogo'],
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 38.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                            info['orderType'] == "delivery"
                                ? "${LocaleData.delivery.getString(context)}:"
                                : "${LocaleData.takeaway.getString(context)}:",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                    SizedBox(
                      height: 24.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${LocaleData.ordertime.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            )),
                        Text(info['time'],
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            info['orderType'] == "delivery"
                                ? "${LocaleData.delivery.getString(context)}:"
                                : "${LocaleData.takeaway.getString(context)}:",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            )),
                        Text(
                            info['orderType'] == "delivery"
                                ? "${LocaleData.deliverytime40.getString(context)}"
                                : "${LocaleData.deliverytime15.getString(context)}",
                            style: TextStyle(
                              fontSize: 17,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            ))
                      ],
                    ),
                    Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Action for confirmation
                          print("Hello Babu");
                          Order.clearOrder();
                          Bonus.clean();
                          Get.offAll(() => MenuScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: cBlack,
                          backgroundColor: cWhite, // Text color for the button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Text('OK', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';
import 'package:sushi_alpha_project/LocalMemory/HistoryOrder.dart';

import '../../Backend/Api.dart';
import '../../Components/Profile/OrderTrack/MyTimeLine.dart';
import '../../Localzition/locals.dart';

class OrderTrackScreen extends StatefulWidget {
  const OrderTrackScreen({super.key});

  @override
  State<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends State<OrderTrackScreen> {
  late Map info;
  late Future<String> orderState;

  @override
  void initState() {
    super.initState();
    info = Get.arguments;
    orderState = Api.getOrderState(info['orderId']);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print(info);
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cDarkGreen,
        ),
        title: cAppBarTittle(text: '${LocaleData.track.getString(context)}'),
        actions: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: FeedbackForm(
                      orderId: info['orderId'],
                    ),
                  );
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: cDarkGreen,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '${LocaleData.feedback.getString(context)}',
                style: TextStyle(color: cWhite),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cDarkGreen,
        onRefresh: () async {
          HapticFeedback.heavyImpact();
          setState(() {
            orderState = Api.getOrderState(info['orderId']);
          });
        },
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Column(
              children: [
                FutureBuilder<String>(
                  future: orderState,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      String? data = snapshot.data;

                      if (data == "404") {
                        return Column(
                          children: [
                            Container(
                              width: 250,
                              height: 250,
                              child: SvgPicture.asset(
                                "assets/images/вектор.svg",
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Order not found",
                              style: TextStyle(
                                fontSize: 17,
                                color: cDarkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        );
                      }

                      if (info['type'] == "delivery") {
                        List<String> stateData = [
                          '',
                          'accept',
                          'cooking',
                          'delivery',
                          'finished'
                        ];
                        int index = stateData.indexOf(data!);
                        return Column(
                          children: [
                            MyTimeLine(
                              isFirst: true,
                              sizeContainer: 0.12,
                              isLast: false,
                              isPast: index >= 1,
                              imageName: "assets/orderSteat/orderTaken.png",
                              processName:
                                  '${LocaleData.accepted.getString(context)}',
                            ),
                            MyTimeLine(
                              isFirst: false,
                              isLast: false,
                              sizeContainer: 0.12,
                              isPast: index >= 2,
                              imageName: "assets/orderSteat/orderCooking.png",
                              processName:
                                  '${LocaleData.inpreparation.getString(context)}',
                            ),
                            MyTimeLine(
                              isFirst: false,
                              isLast: false,
                              sizeContainer: 0.12,
                              isPast: index >= 3,
                              imageName: "assets/orderSteat/orderOnWay.png",
                              processName:
                                  '${LocaleData.ontheway.getString(context)}',
                            ),
                            MyTimeLine(
                              isFirst: false,
                              isLast: true,
                              sizeContainer: 0.12,
                              isPast: index >= 4,
                              imageName: "assets/orderSteat/orderDelivered.png",
                              processName:
                                  '${LocaleData.delivered.getString(context)}',
                            ),
                          ],
                        );
                      } else {
                        List<String> stateData = [
                          '',
                          'accept',
                          'cooking',
                          'finished'
                        ];
                        int index = stateData.indexOf(data!);
                        return Column(
                          children: [
                            MyTimeLine(
                              isFirst: true,
                              isLast: false,
                              sizeContainer: 0.18,
                              isPast: index >= 1,
                              imageName: "assets/orderSteat/orderTaken.png",
                              processName:
                                  '${LocaleData.accepted.getString(context)}',
                            ),
                            MyTimeLine(
                              isFirst: false,
                              isLast: false,
                              sizeContainer: 0.18,
                              isPast: index >= 2,
                              imageName: "assets/orderSteat/orderCooking.png",
                              processName:
                                  '${LocaleData.inpreparation.getString(context)}',
                            ),
                            MyTimeLine(
                              isFirst: false,
                              isLast: true,
                              sizeContainer: 0.18,
                              isPast: index >= 3,
                              imageName: "assets/orderSteat/orderDelivered.png",
                              processName:
                                  '${LocaleData.ready.getString(context)}',
                            ),
                          ],
                        );
                      }
                    } else {
                      return const Text('');
                    }
                  },
                ),
                SizedBox(height: 30.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: cDarkGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${LocaleData.orderid.getString(context)} :  ${info['orderId']}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "${LocaleData.ordertime.getString(context)}: ${info['date']}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "${LocaleData.paymentmethods.getString(context)}: ${info['payment_method'] == "cash" ? LocaleData.cash.getString(context) : LocaleData.card.getString(context)}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "${LocaleData.type.getString(context)}: ${info['type'] == "delivery" ? LocaleData.delivery.getString(context) : LocaleData.takeaway.getString(context)}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        "${LocaleData.total.getString(context)}: ${info['sum']}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 33.h),
                      Column(
                        children: products(),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> products() {
    List<Widget> result = [];
    List data = HistoryOrder.getHistoryOrderProducts(info['id']);
    result = List.generate(data.length, (index) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        margin: EdgeInsets.only(bottom: 15.h),
        decoration: BoxDecoration(
          color: cWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 90.w,
              height: 90.h,
              child: cImage(name: data[index]['photo']),
            ),
            SizedBox(width: 22.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${data[index]['price']} ${LocaleData.som.getString(context)}",
                    style: const TextStyle(
                      fontSize: 17,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${data[index]['name']}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 17,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${data[index]['amount']} ${LocaleData.pc.getString(context)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    });
    return result;
  }
}

class FeedbackForm extends StatelessWidget {
  final String orderId;

  FeedbackForm({required this.orderId});

  final TextEditingController someController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${LocaleData.feedbackForOrder.getString(context)} $orderId',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: someController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  '${LocaleData.writeYourFeedbackHere.getString(context)}',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: cWhite,
              backgroundColor: cDarkGreen,
            ),
            onPressed: () {
              // Submit feedback logic

              print("---------");

              Map data = {'feedback': someController.text};

              String jsonString = jsonEncode(data);

              print(orderId);
              print(jsonString);

              Api.sendFeedback(orderId, jsonString);
              Get.back(); // Close modal after feedback submission
            },
            child: Text('${LocaleData.submit.getString(context)}'),
          ),
        ],
      ),
    );
  }
}

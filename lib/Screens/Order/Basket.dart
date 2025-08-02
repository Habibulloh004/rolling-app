import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/LocalMemory/Order.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Backend/Api.dart';
import '../../Consts/Functions.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../Authentication/RegistrationScreen.dart';
import 'BasketBonus.dart';
import 'PaymentAndLocation.dart';

class BasketScreen extends StatefulWidget {
  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  late String price;
  late String priceWithDelivery;
  late Future<int> getOrderPrice;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOrderPrice = Api.getDeliveryPrice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${LocaleData.basket.getString(context)}'),
          leading: IconButton(
              onPressed: () {
                Get.offAll(() => MenuScreen());
              },
              icon: Icon(
                Icons.navigate_before,
                color: cDarkGreen,
                size: 30,
              )),
        ),
        body: FutureBuilder(
          future: getOrderPrice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Display a loading indicator while waiting for the future to complete
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: cGray,
                  valueColor: AlwaysStoppedAnimation<Color>(cDarkGreen),
                ),
              );
            } else if (snapshot.hasError) {
              // If the future completes with an error, display the error
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              print("-------------------");
              print(Order.isNoOrder());
              if (Order.isNoOrder()) {
                return Column(
                  children: [
                    Center(
                        child: Column(
                      children: [
                        SizedBox(
                          height: 100,
                        ),
                        Container(
                          width: 200,
                          height: 200,
                          child: SvgPicture.asset(
                            "assets/images/вектор.svg",
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "${LocaleData.yourbasketisempty.getString(context)}",
                          style: TextStyle(
                            fontSize: 25,
                            color: cDarkGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: 300,
                          child: Text(textAlign: TextAlign.center, ""),
                        ),
                      ],
                    )),
                  ],
                );
              } else {
                int? deliveryPriceInt = snapshot.data;
                String deliveryPriceStr = makePriceSomString(deliveryPriceInt!);

                price = Order.getOrderPrice()['string'];
                print("*****************");
                print(price);
                priceWithDelivery = makePriceSomString(
                    Order.getOrderPrice()['int'] + deliveryPriceInt);

                return Column(
                  children: [
                    Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            children: basketInfo(),
                          ),
                        )),
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
                            crossAxisAlignment: CrossAxisAlignment
                                .stretch, // Stretch the column to the width of the screen/container
                            children: [
                              SizedBox(
                                height: 25.h,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(LocaleData.products.getString(context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cWhite,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  Text(
                                      "${price} ${LocaleData.som.getString(context)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cWhite,
                                        fontWeight: FontWeight.w400,
                                      ))
                                ],
                              ),
                              SizedBox(
                                height: 20.h,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(LocaleData.delivery.getString(context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cWhite,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  Text(
                                      "${deliveryPriceStr} ${LocaleData.som.getString(context)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cWhite,
                                        fontWeight: FontWeight.w400,
                                      ))
                                ],
                              ),
                              SizedBox(
                                height: 20.h,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    LocaleData.total.getString(context),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: cWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // if (haveDiscount == false &&
                                      //     !User.isUserExists())
                                      Text(
                                        "${priceWithDelivery} ${LocaleData.som.getString(context)}",
                                        style: TextStyle(
                                          color: cWhite,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // if (haveDiscount == true ||
                                      //     User.isUserExists())
                                      //   Column(
                                      //     children: [
                                      //       Text(
                                      //         "${priceWithDelivery} ${LocaleData.som.getString(context)}",
                                      //         style: TextStyle(
                                      //           color: cWhite,
                                      //           fontSize: 10.sp,
                                      //           decoration:
                                      //               TextDecoration.lineThrough,
                                      //           decorationColor: Colors.red,
                                      //           decorationThickness: 2,
                                      //         ),
                                      //       ),
                                      //       Text(
                                      //         "${Order.getOrderPrice50AndDelivery()['string']} ${LocaleData.som.getString(context)}",
                                      //         style: TextStyle(
                                      //           fontSize: 17,
                                      //           color: Colors.white,
                                      //           fontWeight: FontWeight.w600,
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   )
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: 24.h), // Space before the buttons
                              ElevatedButton(
                                onPressed: () {
                                  if (User.isUserExists()) {
                                    Get.to(() => RegistrationScreen());
                                  } else {
                                    Get.to(() => BasketBonusScreen());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: cBlack,
                                  backgroundColor:
                                      cWhite, // Text color for the button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  child: Text(
                                      LocaleData.usebonus.getString(context),
                                      style: TextStyle(fontSize: 14.sp)),
                                ),
                              ),
                              Spacer(),
                              // SizedBox(
                              //     height: 12.h), // Space between the buttons
                              ElevatedButton(
                                onPressed: () {
                                  if (User.isUserExists()) {
                                    Get.to(() => RegistrationScreen());
                                  } else {
                                    Get.to(() => PaymentAndLocationScreen());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: cBlack,
                                  backgroundColor:
                                      cWhite, // Text color for the button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  child: Text(
                                      LocaleData.confirm.getString(context),
                                      style: TextStyle(fontSize: 14.sp)),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            } else {
              return Text('No data available');
            }
          },
        ));
  }

  List<Widget> basketInfo() {
    List<Widget> result = [];

    result = List.generate(
      Order.getOrderLength(),
      (index) => Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(),
        child: Row(
          children: [
            //image
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              margin: EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                width: 90.w,
                height: 90.h,
                child: InstaImageViewer(
                  child: cImage(
                    name: Order.getOrderAt(index)['photo'],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 20.w,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${Order.getOrderAt(index)['price']} ${LocaleData.som.getString(context)}",
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Order.getOrderAt(index)['name'],
                    style: TextStyle(
                      fontSize: 17,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                      '${Order.getOrderAt(index)['amount']} ${LocaleData.pc.getString(context)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cDarkGreen,
                        fontWeight: FontWeight.w400,
                      )),
                  SizedBox(
                    height: 5.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              Colors.white, // Background color of the container
                          border: Border.all(
                              color: Colors.grey.shade300), // Border color
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ], // Corner radius
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              child: Container(
                                width: 24.w,
                                height: 20.h,
                                child: IconButton(
                                  icon: Icon(Icons.remove,
                                      size: 14), // Smaller icon
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2), // Reduced padding
                                  // constraints: BoxConstraints(), // Removes size constraints
                                  onPressed: () {
                                    setState(() {
                                      int amount = int.parse(
                                          Order.getOrderAt(index)['amount']);
                                      amount -= 1;
                                      print(Order.getOrderLength());
                                      if (amount >= 1) {
                                        Order.getOrderAt(index)['amount'] =
                                            '${amount}';
                                      } else if (Order.getOrderLength() == 1 &&
                                          amount == 0) {
                                        Order.deleteOrderAt(index);
                                        Get.offAll(() => MenuScreen());
                                      } else {
                                        Order.deleteOrderAt(index);
                                      }
                                      price = Order.getOrderPrice()['string'];
                                      priceWithDelivery =
                                          Order.getOrderPriceWithDelivery()[
                                              'string'];
                                    });
                                  },
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(),
                              child: Container(
                                width: 22.w,
                                height: 20.h,
                                child: Text(
                                  Order.getOrderAt(
                                      index)['amount'], // The current quantity
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            Container(
                              child: Container(
                                width: 24.w,
                                height: 20.h,
                                child: IconButton(
                                  icon:
                                      Icon(Icons.add, size: 14), // Smaller icon
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2), // Reduced padding
                                  constraints:
                                      BoxConstraints(), // Removes size constraints
                                  onPressed: () {
                                    setState(() {
                                      int amount = int.parse(
                                          Order.getOrderAt(index)['amount']);
                                      amount += 1;
                                      if (amount <= 10) {
                                        Order.getOrderAt(index)['amount'] =
                                            '${amount}';
                                      }
                                      price = Order.getOrderPrice()['string'];
                                      priceWithDelivery =
                                          Order.getOrderPriceWithDelivery()[
                                              'string'];
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            Order.deleteOrderAt(index);
                            if (Order.getOrderLength() == 0) {
                              Get.offAll(() => MenuScreen());
                            }
                            price = Order.getOrderPrice()['string'];
                            priceWithDelivery =
                                Order.getOrderPriceWithDelivery()['string'];
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(
                              4), // Padding to shrink the size of the container
                          decoration: BoxDecoration(
                            color: cWhite, // Background color of the container
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ], // Corner radius
                          ),
                          child: Icon(
                            Icons.delete,
                            color: cDarkGreen,
                            size: 24,
                          ), // Smaller delete icon
                          // If you need the trash icon to be clickable, wrap it with an IconButton instead.
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );

    return result;
  }
}

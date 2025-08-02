import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';

import '../../Backend/Api.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Bonus.dart';
import '../../LocalMemory/Order.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../Authentication/RegistrationScreen.dart';
import '../Menu/Menu.dart';
import 'PaymentAndLocation.dart';

class BasketBonusScreen extends StatefulWidget {
  @override
  State<BasketBonusScreen> createState() => _BasketBonusScreenState();
}

class _BasketBonusScreenState extends State<BasketBonusScreen> {
  final TextEditingController bonusController = TextEditingController();
  int bonus = 0;
  String bonusString = '';
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.offAll(() => MenuScreen());
          },
          color: cDarkGreen,
        ),
        title: Text('Корзина'),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: basketInfo(),
                ),
              )),
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(bottom: size.height * 0.04),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          LocaleData.bonuses.getString(context),
                          style: TextStyle(
                            fontSize: 20,
                            color: cWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    FutureBuilder(
                      future:
                          Api.getUserBonus(), // Replace with your future method
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("Загрузка...",
                              style: TextStyle(color: Colors.white));
                        } else if (snapshot.hasError) {
                          return Text("Ошибка: ",
                              style: TextStyle(color: Colors.white));
                        } else {
                          bonus =
                              snapshot.data['string'] == "что-то пошло не так"
                                  ? 0
                                  : snapshot.data['int'];
                          bonusString = snapshot.data['string'];

                          return Text(
                            snapshot.data['string'] == "что-то пошло не так"
                                ? "что-то пошло не та"
                                : " ${LocaleData.availablebonuses.getString(context)} ${snapshot.data['string']} сум",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 28.h),
                    Row(
                      children: [
                        Text("${LocaleData.choosetheamount.getString(context)}",
                            style: TextStyle(
                              fontSize: 14,
                              color: cWhite,
                              fontWeight: FontWeight.w400,
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Container(
                      child: TextFormField(
                        controller: bonusController,
                        decoration: InputDecoration(
                          hintText: '${LocaleData.bonuses.getString(context)}',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.fromLTRB(20, 10, 20,
                              10), // Left, Top, Right, Bottom padding
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () {
                        print(bonusController.text);
                        print(bonus);
                        if (int.parse(bonusController.text) > bonus) {
                          Get.snackbar(
                            'Неверный номер', // title
                            '', // message
                            snackPosition:
                                SnackPosition.BOTTOM, // Display at the bottom
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } else if (int.parse(bonusController.text) <= -1) {
                          Get.snackbar(
                            'Неверный номер', // title
                            '', // message
                            snackPosition:
                                SnackPosition.BOTTOM, // Display at the bottom
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } else {
                          //Compare twoe numbers,
                          if (Order.getOrderPrice()['int'] >=
                              int.parse(bonusController.text)) {
                            final formatter = NumberFormat('#,###', 'en_US');
                            // Replace commas with spaces
                            final priceResult = formatter
                                .format(int.parse(bonusController.text))
                                .replaceAll(',', ' ');

                            print(priceResult);

                            Bonus.setBonus("bonus", {
                              'int': int.parse(bonusController.text),
                              'string': priceResult,
                            });

                            if (User.isUserExists()) {
                              Get.to(() => RegistrationScreen());
                            } else {
                              Get.to(() => PaymentAndLocationScreen());
                            }
                          } else {
                            Get.snackbar(
                              'Вы используете больше бонусов, чем стоимость заказа', // title
                              '', // message
                              snackPosition:
                                  SnackPosition.BOTTOM, // Display at the bottom
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        }
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
                        child: Text('${LocaleData.confirm.getString(context)}',
                            style: TextStyle(fontSize: 16)),
                      ),
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
                    child: cImage(name: Order.getOrderAt(index)['photo'])),
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

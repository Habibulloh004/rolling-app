import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/LocalMemory/Bonus.dart';
import 'package:sushi_alpha_project/LocalMemory/Location.dart';
import 'package:sushi_alpha_project/Screens/Map/map_screen.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Backend/Api.dart';
import '../../Consts/Functions.dart';
import '../../Consts/Restoranse.dart';
import '../../LocalMemory/CreditCard.dart';
import '../../LocalMemory/HistoryOrder.dart';
import '../../LocalMemory/Language.dart';
import '../../LocalMemory/Order.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../CreditCard/CardOTP.dart';
import '../CreditCard/CreditCard.dart';
import 'endOfOrder.dart';

class PaymentAndLocationScreen extends StatefulWidget {
  @override
  State<PaymentAndLocationScreen> createState() =>
      _PaymentAndLocationScreenState();
}

class _PaymentAndLocationScreenState extends State<PaymentAndLocationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool cash = !CreditCard.getUserChoseCard();
  bool creditCard = CreditCard.getUserChoseCard();
  late Future<int> getOrderPrice;
  String typeOfOrder = "delivery";

  final TextEditingController addressCommentController =
      TextEditingController();

  String iconDelivery = "assets/Icons/delivery_white.png";
  String iconTakeAway = "assets/Icons/take-away.png";
  // Default value assuming no discount

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getOrderPrice = Api.getDeliveryPrice();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Print or handle the index of the tab that was clicked
        setState(() {
          typeOfOrder = _tabController.index == 0 ? "delivery" : "take_away";
        });

        if (_tabController.index == 0) {
          iconDelivery = "assets/Icons/delivery_white.png";
          iconTakeAway = "assets/Icons/take-away.png";
        } else {
          iconDelivery = "assets/Icons/delivery.png";
          iconTakeAway = "assets/Icons/take-away_white.png";
        }

        print('Tab changed to index: ${_tabController.index}');
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  List<bool> locationsBoolList = List.generate(
      MapLocation.getLength(), (index) => index == 0 ? true : false);
  int bonus = Bonus.isBonusExists() ? Bonus.getBonus('bonus')['int'] : 0;
  List<bool> restaurant = [true, false, false];
  List<String> restaurantText = [
    'Rolling Sushi  "Olmazor"',
    'Rolling Sushi  "Yakkasaroy"',
    'Rolling Sushi  "Mirzo-Ulug’bek"',
  ];
  int indexOfResturant = 0;

  @override
  Widget build(BuildContext context) {
    final List<Tab> _tabs = [
      Tab(
        icon: Container(
          width: 20.w,
          height: 20.w,
          child: Image.asset(iconDelivery),
        ),
        text: "${LocaleData.delivery.getString(context)}",
      ),
      Tab(
        icon: Container(
          width: 20.w,
          height: 20.w,
          child: Image.asset(iconTakeAway),
        ),
        text: "${LocaleData.takeaway.getString(context)}",
      ),
    ];
    return Scaffold(
        appBar: AppBar(
          title: Text("${LocaleData.basket.getString(context)}"),
          leading: IconButton(
              onPressed: () {
                Get.to(() => MenuScreen());
                if (Bonus.isBonusExists()) {
                  Bonus.clean();
                }
              },
              icon: Icon(
                Icons.navigate_before,
                color: cDarkGreen,
                size: 30,
              )),
        ),
        body: FutureBuilder(
          future:
              getOrderPrice, // Your async function to check if the discount exists
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
              // Once the data is available, use it to build widgets
              // bool? haveDiscount = snapshot .data;
              // This will hold your boolean value from the future

              int? deliveryPriceInt = snapshot.data;
              String deliveryPriceStr = makePriceSomString(deliveryPriceInt!);
              String orderPriceStr = Order.getOrderPrice()['string'];
              int orderPriceInt = Order.getOrderPrice()['int'];
              int bonusInt = bonus;
              String bonusStr = makePriceSomString(bonus);
              int getOrderPriceWithBonusInt = (orderPriceInt - bonus);
              String getOrderPriceWithBonusStr =
                  makePriceSomString(getOrderPriceWithBonusInt);
              int getOrderPriceWithDeliveryInt =
                  (orderPriceInt + deliveryPriceInt);
              String getOrderPriceWithDeliveryStr =
                  makePriceSomString(getOrderPriceWithDeliveryInt);
              int getOrderPriceWithDeliveryAndBonusInt =
                  (orderPriceInt + deliveryPriceInt - bonusInt);
              String getOrderPriceWithDeliveryAndBonusStr =
                  makePriceSomString(getOrderPriceWithDeliveryAndBonusInt);

              return Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: Container(
                            child: TabBar(
                              controller: _tabController,
                              tabs: _tabs,
                              labelColor: cWhite,
                              indicatorColor: cDarkGreen,
                              unselectedLabelColor: cDarkGreen,
                              indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: cDarkGreen),
                              indicatorSize: TabBarIndicatorSize.tab,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 20),
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          color: cGray,
                                          width: 2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${LocaleData.paymentmethods.getString(context)}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cDarkGreen,
                                            )),
                                        SizedBox(height: 15.h),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              cash = true;
                                              creditCard = false;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${LocaleData.cash.getString(context)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: cash
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 15.h),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              cash = false;
                                              creditCard = true;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${LocaleData.card.getString(context)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: creditCard
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 15.h),
                                        TextFormField(
                                          controller: addressCommentController,
                                          readOnly:
                                              true, // Prevent manual input
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey,
                                                  width: 2.0),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide:
                                                  BorderSide(width: 2.0),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            labelText:
                                                " ${LocaleData.addCommentsForLocation.getString(context)}",
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            prefixIcon: Icon(Icons.comment),
                                          ),
                                          onTap: () {
                                            // Show the bottom sheet
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            20)),
                                              ),
                                              builder: (BuildContext context) {
                                                return FeedbackBottomSheet(
                                                  onSubmit: (String comment) {
                                                    setState(() {
                                                      addressCommentController
                                                          .text = comment;
                                                    });
                                                    Navigator.pop(
                                                        context); // Close the bottom sheet
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: 20.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                "${LocaleData.location.getString(context)}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: cDarkGreen,
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Get.to(MapScreen(),
                                                      arguments: {
                                                        'action': 'add'
                                                      })?.then((value) {
                                                    setState(() {
                                                      locationsBoolList =
                                                          List.generate(
                                                              MapLocation
                                                                  .getLength(),
                                                              (index) =>
                                                                  index == 0
                                                                      ? true
                                                                      : false);
                                                    });
                                                  });
                                                },
                                                child: Text(
                                                  "${LocaleData.chooselocation.getString(context)}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: cBlack,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ))
                                          ],
                                        ),
                                        Column(
                                          children: locations(),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 20),
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          color: cGray,
                                          width: 2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Filyalli tanlang",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cDarkGreen,
                                            )),
                                        SizedBox(height: 15.h),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              cash = true;
                                              creditCard = false;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${LocaleData.cash.getString(context)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: cash
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 15.h),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              cash = false;
                                              creditCard = true;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${LocaleData.card.getString(context)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: creditCard
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 30.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                "${LocaleData.location.getString(context)}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: cDarkGreen,
                                                )),
                                          ],
                                        ),
                                        //
                                        SizedBox(
                                          height: 15.h,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              restaurant[0] = true;
                                              restaurant[1] = false;
                                              restaurant[2] = false;
                                              indexOfResturant = 0;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${Language.getLanguage() == 'ru' ? cRestoanInfo[0]['nameRU'] : cRestoanInfo[0]['nameUZ']}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: restaurant[0]
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 15.h,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              restaurant[0] = false;
                                              restaurant[1] = true;
                                              restaurant[2] = false;
                                              indexOfResturant = 1;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${Language.getLanguage() == 'ru' ? cRestoanInfo[1]['nameRU'] : cRestoanInfo[1]['nameUZ']}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: restaurant[1]
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 15.h,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              restaurant[0] = false;
                                              restaurant[1] = false;
                                              restaurant[2] = true;
                                              indexOfResturant = 2;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  cDarkGreen, // Adjust the color to match your design
                                              borderRadius: BorderRadius.circular(
                                                  5.0), // Adjust for the desired curvature
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Use min to wrap content size
                                              children: <Widget>[
                                                Text(
                                                  '${Language.getLanguage() == 'ru' ? cRestoanInfo[2]['nameRU'] : cRestoanInfo[2]['nameUZ']}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16.0, // Adjust the font size as needed
                                                  ),
                                                ), // Space between text and icon
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: cDarkGreen,
                                                    border: Border.all(
                                                        width: 2,
                                                        color: cWhite),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: restaurant[2]
                                                      ? Icon(
                                                          Icons.check,
                                                          color: cWhite,
                                                          size: 15,
                                                        )
                                                      : null,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 15.h,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Stretch the column to the width of the screen/container
                          children: [
                            SizedBox(
                              height: 25.h,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "${LocaleData.products.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cWhite,
                                      fontWeight: FontWeight.w400,
                                    )),
                                Text(
                                    "${orderPriceStr} ${LocaleData.som.getString(context)}",
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "${LocaleData.delivery.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cWhite,
                                      fontWeight: FontWeight.w400,
                                    )),
                                Text(
                                    typeOfOrder == "delivery"
                                        ? "${deliveryPriceStr} ${LocaleData.som.getString(context)}"
                                        : "0 ${LocaleData.som.getString(context)}",
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "${LocaleData.bonuslowercase.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cWhite,
                                      fontWeight: FontWeight.w400,
                                    )),
                                Text(
                                    Bonus.isBonusExists()
                                        ? Bonus.getBonus('bonus')['string'] +
                                            " ${LocaleData.som.getString(context)}"
                                        : "0 ${LocaleData.som.getString(context)}",
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${LocaleData.total.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: cWhite,
                                      fontWeight: FontWeight.w600,
                                    )),
                                Text(
                                    typeOfOrder == "delivery"
                                        ? "${Bonus.isBonusExists() ? getOrderPriceWithDeliveryAndBonusStr : getOrderPriceWithDeliveryStr} ${LocaleData.som.getString(context)}"
                                        : "${Bonus.isBonusExists() ? getOrderPriceWithBonusStr : orderPriceStr} ${LocaleData.som.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: cWhite,
                                      fontWeight: FontWeight.w600,
                                    ))
                              ],
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                // //current date
                                getLatLong();
                                DateTime now = DateTime.now();
                                String formattedDateTime =
                                    DateFormat('dd.MM.yyyy HH:mm').format(now);

                                // clicked += 1;

                                // if (clicked < 2) {
                                showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: cDarkGreen,
                                        ),
                                      );
                                    });

                                //Check if making order is possible,
                                bool isAllowedToTakeOrder =
                                    await Api.isRestaurantOpen();
                                // bool isAllowedToTakeOrder = true;

                                if (!isAllowedToTakeOrder) {
                                  Navigator.pop(context);
                                  Get.snackbar(
                                    "${LocaleData.therestaurantisclosed.getString(context)}", // title
                                    '', // message
                                    snackPosition: SnackPosition
                                        .BOTTOM, // Display at the bottom
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  // Navigator.pop(context);
                                  if (MapLocation.isNoMaps()) {
                                    Navigator.pop(context);
                                    Get.snackbar(
                                      "${LocaleData.firstselectalocation.getString(context)}", // title
                                      '', // message
                                      snackPosition: SnackPosition
                                          .BOTTOM, // Display at the bottom
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  } else {
                                    FirebaseMessaging messaging =
                                        FirebaseMessaging.instance;

                                    String? fcmToken =
                                        await messaging.getToken();

                                    final int payed_sum = typeOfOrder ==
                                            "delivery"
                                        ? Bonus.isBonusExists()
                                            ? getOrderPriceWithDeliveryAndBonusInt *
                                                100
                                            : getOrderPriceWithDeliveryInt * 100
                                        : Bonus.isBonusExists()
                                            ? getOrderPriceWithBonusInt * 100
                                            : orderPriceInt * 100;

                                    Map<String, dynamic> orderMapData = {
                                      'created_at': formattedDateTime,
                                      'type': typeOfOrder == "delivery"
                                          ? typeOfOrder
                                          : typeOfOrder +
                                              " " +
                                              restaurantText[indexOfResturant],
                                      'products': Order.getOrderAmountAndId()
                                          .toString(),
                                      'client_address': getLatLong().toString(),
                                      'client_id':
                                          User.getUserInfo('id').toString(),
                                      'phone':
                                          User.getUserInfo('phone').toString(),
                                      'comment': "no",
                                      'all_price': typeOfOrder == "delivery"
                                          ? getOrderPriceWithDeliveryInt * 100
                                          : orderPriceInt * 100,
                                      'payment':
                                          creditCard ? "creditCard" : "cash",
                                      'promotion': 'no',
                                      'status': '',
                                      'spot_id': '0',
                                      'payed_bonus': Bonus.isBonusExists()
                                          ? bonusInt * 100
                                          : 0,
                                      'payed_sum': payed_sum,
                                      'fcm': fcmToken,
                                      'fcm_lng': Language.getLanguage(),
                                      "address_comment":
                                          addressCommentController.text
                                      //addressCommentController
                                    };

                                    int priceOfOrder = typeOfOrder == "delivery"
                                        ? Bonus.isBonusExists()
                                            ? getOrderPriceWithDeliveryAndBonusInt
                                            : getOrderPriceWithDeliveryInt
                                        : Bonus.isBonusExists()
                                            ? getOrderPriceWithBonusInt
                                            : orderPriceInt;

                                    String priceOfOrderString = typeOfOrder ==
                                            "delivery"
                                        ? "${Bonus.isBonusExists() ? getOrderPriceWithDeliveryAndBonusStr : getOrderPriceWithDeliveryStr} ${LocaleData.som.getString(context)}"
                                        : "${Bonus.isBonusExists() ? getOrderPriceWithBonusStr : orderPriceStr} ${LocaleData.som.getString(context)}";

                                    Map infoToLastScreen = {
                                      'orderType': typeOfOrder == "delivery"
                                          ? typeOfOrder
                                          : typeOfOrder +
                                              " " +
                                              restaurantText[indexOfResturant],
                                      'discount': false,
                                      'itogo': priceOfOrderString,
                                      'bonus': Bonus.isBonusExists()
                                          ? bonusStr +
                                              " ${LocaleData.som.getString(context)}"
                                          : "0 ${LocaleData.som.getString(context)}",
                                      'time': formattedDateTime,
                                      'deliveryPrice': deliveryPriceStr,
                                    };

                                    if (creditCard) {
                                      if (CreditCard.getCreditCardName()
                                          is! String) {
                                        Get.off(
                                          () => CardScreen(),
                                          arguments: "fromPaymentAndLocation",
                                        );
                                        CreditCard.setUserChoseCard();
                                      } else {
                                        Map<String, String> data =
                                            await Api.payCreditCard(
                                                priceOfOrder);
                                        //chech if work or not
                                        if (data['status'] != "failed") {
                                          //Make the order
                                          Get.off(() => CardOTP(), arguments: [
                                            orderMapData,
                                            data['session'],
                                            infoToLastScreen,
                                          ]);
                                        } else {
                                          Navigator.pop(context);
                                          Get.snackbar(
                                            "${LocaleData.somethingwentwrong.getString(context)}", // title
                                            '${LocaleData.checkyourcard.getString(context)}', // message
                                            snackPosition: SnackPosition
                                                .BOTTOM, // Display at the bottom
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                          Navigator.pop(context);
                                        }
                                      }
                                    } else {
                                      //Cashe payment

                                      String orderId =
                                          await Api.giveOrder(orderMapData);
                                      if (orderId == 'error') {
                                        Get.snackbar(
                                          "${LocaleData.somethingwentwrong.getString(context)}", // title
                                          '', // message
                                          snackPosition: SnackPosition
                                              .BOTTOM, // Display at the bottom
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                      } else {
                                        // Up gerding the client group
                                        await userUpDateGroupe();

                                        // //current date
                                        DateTime now = DateTime.now();
                                        String formattedDateTime =
                                            DateFormat('dd.MM.yyyy HH:mm')
                                                .format(now);

                                        Map data = {
                                          'id': orderId,
                                          'date': formattedDateTime,
                                          'priceOfOrderString':
                                              priceOfOrderString,
                                          'products': Order.getFullOrder(),
                                          'payment_method': 'cash',
                                          'type': typeOfOrder == "delivery"
                                              ? typeOfOrder
                                              : typeOfOrder +
                                                  " " +
                                                  restaurantText[
                                                      indexOfResturant],
                                        };

                                        //Add order to history Localy
                                        HistoryOrder.addHistoryOrder(data);

                                        Get.offAll(() => EndOFOrderScreen(),
                                            arguments: infoToLastScreen);
                                      }
                                    }
                                  }
                                }
                                // }
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
                                    '${LocaleData.confirorder.getString(context)}',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // This scenario will occur if no error, no data, and not waiting
              return Text('No data available');
            }
          },
        ));
  }

  List<Widget> locations() {
    // List reversedLocationName =

    List<Widget> result = List.generate(
      locationsBoolList.length,
      (index) {
        print("--------");
        // print(MapLocation.getLocationAt(index));
        //locationsBoolList.length - cunnrent index
        print(MapLocation.getLocationAt(
            (locationsBoolList.length - 1) - index)['name']);
        String name = MapLocation.getLocationAt(
            (locationsBoolList.length - 1) - index)['name'];

        return GestureDetector(
          onTap: () {
            setState(() {
              locationsBoolList = List.generate(
                  MapLocation.getLength(), (i) => i == index ? true : false);
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: cDarkGreen, // Adjust the color to match your design
              borderRadius: BorderRadius.circular(
                  5.0), // Adjust for the desired curvature
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Use min to wrap content size
              children: <Widget>[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: cWhite,
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0, // Adjust the font size as needed
                        ),
                      ),
                    ),
                  ],
                ), // Space between text and icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cDarkGreen,
                    border: Border.all(width: 2, color: cWhite),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: locationsBoolList[index]
                      ? Icon(
                          Icons.check,
                          color: cWhite,
                          size: 15,
                        )
                      : null,
                )
              ],
            ),
          ),
        );
      },
    );

    return result;
  }

  String getLatLong() {
    String resulr = '';
    for (int i = 0; i < locationsBoolList.length; i++) {
      if (locationsBoolList[i] == true) {
        Map data =
            MapLocation.getLocationAt((locationsBoolList.length - 1) - i);
        print(data['name']);
        resulr += " ${data['lat'].toString()},";
        resulr += data['lon'].toString();
      }
    }
    return resulr;
  }
}

class FeedbackBottomSheet extends StatelessWidget {
  final Function(String) onSubmit;

  FeedbackBottomSheet({required this.onSubmit});

  final TextEditingController feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${LocaleData.enterComment.getString(context)}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "${LocaleData.writeYourCommentHere.getString(context)}",
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
              // Call the callback with the entered text
              onSubmit(feedbackController.text);
            },
            child: Text(" ${LocaleData.submit.getString(context)}"),
          ),
        ],
      ),
    );
  }
}

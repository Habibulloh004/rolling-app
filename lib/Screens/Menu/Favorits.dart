import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Functions.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';
import 'package:sushi_alpha_project/LocalMemory/Favorits.dart';
import 'package:sushi_alpha_project/Screens/Order/Basket.dart';

import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';

class FavoritsScreen extends StatefulWidget {
  @override
  _FavoritsScreenState createState() => _FavoritsScreenState();
}

class _FavoritsScreenState extends State<FavoritsScreen> {
  final sliderController = CarouselController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<bool> orderBoolList = List.generate(
        Favorites.getLengthFavorite(),
        (index) =>
            Order.isInOrder(Favorites.getFavoriteAt(index)['productId']));
    return Scaffold(
      body: Container(
        color: cDarkGreen,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(
                        Icons.navigate_before,
                        color: cWhite,
                        size: 30,
                      )),
                  Text("${LocaleData.favorites.getString(context)}",
                      style: TextStyle(
                        color: cWhite,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      )),
                  Order.isNoOrder()
                      ? Container(
                          width: 50,
                          height: 50,
                          child: IconButton(
                              onPressed: () {
                                // Get.to(() => BasketScreen());
                                print(Order.isNoOrder());
                              },
                              icon: Image.asset("assets/Icons/busket.png")),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          child: IconButton(
                              onPressed: () {
                                // Get.to(() => BasketScreen());
                                Get.to(() => BasketScreen());
                              },
                              icon:
                                  Image.asset("assets/Icons/busketActive.png")),
                        ),
                ],
              ),
              SizedBox(
                height: 10.h,
              ),
              CarouselSlider.builder(
                carouselController: sliderController,
                options: CarouselOptions(
                  height: 560.h,
                  enableInfiniteScroll: false,
                  // enlargeCenterPage: true,
                ),
                itemCount: Favorites.getLengthFavorite(),
                itemBuilder: (context, index, realIndex) {
                  String productId =
                      Favorites.getFavoriteAt(index)['productId'];
                  cVibration();
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    padding: EdgeInsets.fromLTRB(21.w, 2.h, 21.w, 20.h),
                    decoration: BoxDecoration(
                      color: cWhite,
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 244.w,
                          height: 186.h,
                          child: InstaImageViewer(
                            child: cImage(
                                name: Favorites.getFavoriteAt(index)['photo']),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20.h,
                            ),
                            Text(
                              Favorites.getFavoriteAt(index)['name'],
                              style: TextStyle(
                                color: cDarkGreen,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 18.h),
                            SizedBox(
                              height: size.height * 0.15,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  // textAlign: TextAlign.center,

                                  Favorites.getFavoriteAt(index)['description'],
                                  style: TextStyle(
                                    color: cBlack,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // price
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              child: Text(
                                "${Favorites.getFavoriteAt(index)['price']} сум",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        if (!orderBoolList[index])
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  Order.setOrder(
                                      Favorites.getFavoriteAt(
                                          index)['productId'],
                                      Favorites.getFavoriteAt(index));
                                });
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                    horizontal: 30.w,
                                    vertical: 5.h,
                                  ),
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                    cDarkGreen), // Background color
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        15), // Rounded corners
                                  ),
                                ),
                              ),
                              child: Text(
                                "${LocaleData.add.getString(context)}",
                                style: TextStyle(
                                  color: cWhite,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                        if (orderBoolList[index])
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(20), // Rounded corners
                              border: Border.all(
                                color: cGray, // Border color
                                width: 2.w, // Border width
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      int amount = int.parse(
                                          Order.getOrder(productId)['amount']);
                                      amount -= 1;
                                      if (amount >= 1) {
                                        Order.getOrder(productId)['amount'] =
                                            '${amount}';
                                      } else {
                                        Order.deleteOrder(productId);
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    Icons.remove,
                                    color: cBlack,
                                    size: 14,
                                  ),
                                ),
                                Text(
                                  Order.getOrder(productId)['amount'],
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      int amount = int.parse(
                                          Order.getOrder(productId)['amount']);
                                      amount += 1;
                                      if (amount <= 10) {
                                        Order.getOrder(productId)['amount'] =
                                            '${amount}';
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: cBlack,
                                    size: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Spacer(),
              Container(
                height: 82,
                // margin: EdgeInsets.only(top: size.height * 0.09),
                child: ListView.builder(
                  // Set scrollDirection to horizontal
                  scrollDirection: Axis.horizontal,
                  // The number of items in your list
                  itemCount: Favorites.getLengthFavorite(),
                  // itemBuilder callback to build the widgets dynamically
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          print(index);
                          sliderController.animateToPage(index);
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: cWhite,
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 30,
                              child: cImage(
                                  name:
                                      Favorites.getFavoriteAt(index)['photo']),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 15,
                                  child: Text(
                                    // maybe change in the future

                                    Favorites.getFavoriteAt(index)['name'],
                                    style: TextStyle(
                                      color: cDarkGreen,
                                      fontSize: 5,
                                      fontFamily: 'SF Pro',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 3,
                                ),
                                Container(
                                  width: 40,
                                  child: Text(
                                    'Нежный сливочный сыр, свежий огурец и благородный лосось. Воплощение всей  тонкости и изящества вкуса в наилучшем.',
                                    style: TextStyle(
                                      color: cBlack,
                                      fontSize: 2,
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 2,
                                ),
                                Container(
                                  width: 40,
                                  child: Text(
                                    "Ингредиенты: Лосось Сыр сливочный Огурец",
                                    style: TextStyle(
                                      color: cBlack,
                                      fontSize: 2,
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 5.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

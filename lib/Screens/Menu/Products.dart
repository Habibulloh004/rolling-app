import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Functions.dart';

import '../../Backend/Api.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Favorits.dart';
import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';
import '../../Models/Product.dart';
import '../Order/Basket.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _products;
  final sliderController = CarouselController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _products = Api.getProducts(Get.arguments[0]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: FutureBuilder(
        future: _products,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return returnSkeletonContainer(size);
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Product> category = snapshot.data;
            List<bool> favoritesList = List.generate(category.length,
                (index) => Favorites.isInFavorite(category[index].productId));
            List<bool> orderBoolList = List.generate(category.length,
                (index) => Order.isInOrder(category[index].productId));
            // return returnSkeletonContainer(size);
            return Container(
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
                        Container(
                          width: size.width * 0.7,
                          child: Text(
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              '${splitText(Get.arguments[1])}',
                              style: TextStyle(
                                color: cWhite,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                        Order.isNoOrder()
                            ? Container(
                                width: 50,
                                height: 50,
                                child: IconButton(
                                    onPressed: () {
                                      // Get.to(() => BasketScreen());
                                      print(Order.isNoOrder());
                                    },
                                    icon:
                                        Image.asset("assets/Icons/busket.png")),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                child: IconButton(
                                    onPressed: () {
                                      // Get.to(() => BasketScreen());
                                      Get.offAll(() => BasketScreen());
                                    },
                                    icon: Image.asset(
                                        "assets/Icons/busketActive.png")),
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
                        onPageChanged: (index, reason) {
                          cVibration();
                        },
                        // enlargeCenterPage: true,
                      ),
                      itemCount: category.length,
                      itemBuilder: (context, index, realIndex) {
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        bool data = favoritesList[index];
                                        data = !data;

                                        if (data == true) {
                                          Favorites.setFavorite(
                                              category[index].productId,
                                              category[index].getMap());
                                        } else {
                                          Favorites.deleteFavorite(
                                              category[index].productId);
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      favoritesList[index]
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: cDarkGreen,
                                      size: 30.sp,
                                    ),
                                  )
                                ],
                              ),
                              Container(
                                width: 244.w,
                                height: 186.h,
                                child: InstaImageViewer(
                                    child: cImage(
                                  name: category[index].photo,
                                  width: 244.w,
                                  height: 186.h,
                                )),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20.h,
                                  ),
                                  Text(
                                    splitTextFromCategory(
                                        category[index].description),
                                    style: TextStyle(
                                      color: cDarkGreen,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 18.h),
                                  SizedBox(
                                    // height: size.height * 0.15,
                                    height: 120.h,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        // textAlign: TextAlign.center,

                                        splitText(category[index].description),
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
                              // SizedBox(height: 24.h),
                              // price
                              Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    child: Text(
                                      "${category[index].price} ${LocaleData.som.getString(context)}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Spacer(),
                              SizedBox(height: 20.h),

                              if (!orderBoolList[index])
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        Order.setOrder(
                                            category[index].productId,
                                            category[index].getMap());
                                      });
                                    },
                                    style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.symmetric(
                                          horizontal: 30.w,
                                          vertical: 5.h,
                                        ),
                                      ),
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              cDarkGreen), // Background color
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              15), // Rounded corners
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      LocaleData.add.getString(context),
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
                                    borderRadius: BorderRadius.circular(
                                        20), // Rounded corners
                                    border: Border.all(
                                      color: cGray, // Border color
                                      width: 2.w, // Border width
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            int amount = int.parse(
                                                Order.getOrder(category[index]
                                                    .productId)['amount']);
                                            amount -= 1;
                                            if (amount >= 1) {
                                              Order.getOrder(category[index]
                                                      .productId)['amount'] =
                                                  '${amount}';
                                            } else {
                                              Order.deleteOrder(
                                                  category[index].productId);
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
                                        Order.getOrder(category[index]
                                            .productId)['amount'],
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            int amount = int.parse(
                                                Order.getOrder(category[index]
                                                    .productId)['amount']);
                                            amount += 1;
                                            if (amount <= 10) {
                                              Order.getOrder(category[index]
                                                      .productId)['amount'] =
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

                              SizedBox(
                                height: 3.h,
                              )
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
                        itemCount: category.length,
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 5),
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: cWhite,
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 30,
                                    child: cImage(
                                      name: category[index].photo,
                                      width: 40,
                                      height: 30,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 15,
                                        child: Text(
                                          // maybe change in the future
                                          splitTextFromCategory(
                                              category[index].description),
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
            );
          } else {
            return Center(
                child: Column(
              children: [
                SizedBox(
                  height: 100,
                ),
                Container(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    "assets/images/noInternet.png",
                    fit: BoxFit.scaleDown,
                  ),
                ),
                Text(
                    textAlign: TextAlign.center,
                    "Мы потеряли соединение с вашим интернетом",
                    style: TextStyle(
                      fontSize: 18,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w700,
                    )),
                Container(
                    width: 300,
                    child: Text(
                        textAlign: TextAlign.center,
                        'Или в настоящее время ресторан переполнен заказами')),
              ],
            ));
          }
        },
      ),
    );
  }

  Widget returnSkeletonContainer(Size size) {
    return Container(
      color: cDarkGreen,
      child: SafeArea(
        child: Column(
          children: [
            // Top Row Skeleton
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
                Container(
                  width: size.width * 0.7,
                  child: Text(
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      '${splitText(Get.arguments[1])}',
                      style: TextStyle(
                        color: cWhite,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      )),
                ),
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
                              Get.offAll(() => BasketScreen());
                            },
                            icon: Image.asset("assets/Icons/busketActive.png")),
                      ),
              ],
            ),

            SizedBox(height: 10.h),

            // Carousel Skeleton
            CarouselSlider.builder(
              carouselController: sliderController,
              options: CarouselOptions(
                height: 560.h,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  cVibration();
                },
                // enlargeCenterPage: true,
              ),
              itemCount: 2,
              itemBuilder: (context, index, realIndex) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  padding: EdgeInsets.fromLTRB(21.w, 2.h, 21.w, 0.h),
                  decoration: BoxDecoration(
                    color: cWhite,
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.star_border,
                            ),
                          )
                        ],
                      ),
                      Center(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 200.w,
                            height: 190.h,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20.h,
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 25.h,
                              width: 300.w,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10.h,
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 150.w,
                              height: 25.h,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 300.w,
                              height: 100.h,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // Spacer(),
                          SizedBox(
                            height: 60,
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 300.w,
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100.w,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Spacer(),
                      SizedBox(height: 20.h),

                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100.w,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 3.h,
                      )
                    ],
                  ),
                );
              },
            ),
            Spacer(),

            // Bottom Horizontal List Skeleton
            Container(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }
}

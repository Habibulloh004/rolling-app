import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Backend/Api.dart';
import '../../Consts/Colors.dart';
import '../../Consts/Functions.dart';
import '../../LocalMemory/Favorits.dart';
import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';
import '../../Models/Product.dart';
import '../Order/Basket.dart';

class SeorchScreen extends StatefulWidget {
  @override
  _SeorchScreenState createState() => _SeorchScreenState();
}

class _SeorchScreenState extends State<SeorchScreen> {
  final sliderController = CarouselController();
  late Future<List<Product>> _products;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _products = Api.seorchProduct('су');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: cDarkGreen,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  onChanged: (text) {
                    setState(() {
                      _products = Api.seorchProduct(text);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '${LocaleData.seorch.getString(context)}',
                    hintStyle: TextStyle(color: cDarkGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(80),
                    ),
                    fillColor: cWhite,
                    filled: true,
                    prefixIcon: Icon(Icons.search, color: cDarkGreen),
                  ),
                  style: TextStyle(color: cDarkGreen),
                ),
              ),
              SizedBox(
                height: 10.h,
              ),
              Expanded(
                child: FutureBuilder(
                  future: _products,
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          backgroundColor: cGray,
                          valueColor: AlwaysStoppedAnimation<Color>(cDarkGreen),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      List<Product> category = snapshot.data;
                      List<bool> favoritesList = List.generate(
                          category.length,
                          (index) => Favorites.isInFavorite(
                              category[index].productId));
                      List<bool> orderBoolList = List.generate(
                          category.length,
                          (index) =>
                              Order.isInOrder(category[index].productId));

                      return Column(
                        children: [
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
                                padding:
                                    EdgeInsets.fromLTRB(21.w, 2.h, 21.w, 20.h),
                                decoration: BoxDecoration(
                                  color: cWhite,
                                  borderRadius: BorderRadius.circular(
                                      10), // Rounded corners
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
                                      child:
                                          cImage(name: category[index].photo),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 20.h,
                                        ),
                                        Text(
                                          category[index].name.replaceAll(
                                              RegExp(r'\s*\$\d+$'), ''),
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
                                              splitText(
                                                  category[index].description),
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
                                            "${category[index].price} ${LocaleData.som.getString(context)}",
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
                                                borderRadius:
                                                    BorderRadius.circular(
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
                                                      Order.getOrder(
                                                              category[index]
                                                                  .productId)[
                                                          'amount']);
                                                  amount -= 1;
                                                  if (amount >= 1) {
                                                    Order.getOrder(
                                                            category[index]
                                                                .productId)[
                                                        'amount'] = '${amount}';
                                                  } else {
                                                    Order.deleteOrder(
                                                        category[index]
                                                            .productId);
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
                                                      Order.getOrder(
                                                              category[index]
                                                                  .productId)[
                                                          'amount']);
                                                  amount += 1;
                                                  if (amount <= 10) {
                                                    Order.getOrder(
                                                            category[index]
                                                                .productId)[
                                                        'amount'] = '${amount}';
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
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            width:
                                size.width, // You can adjust padding as needed
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Get.off(() => MenuScreen());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10), // Adjust the border radius here
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 45.w, vertical: 8.h),
                                    backgroundColor:
                                        cWhite, // Set button background color to white
                                    foregroundColor:
                                        cDarkGreen, // Set text and icon color
                                    // Add other styling as needed, such as elevation, textStyle, etc.
                                  ),
                                  child: Text(
                                      "${LocaleData.menu.getString(context)}"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Get.to(() => BasketScreen());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10), // Adjust the border radius here
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 45.w, vertical: 8.h),
                                    backgroundColor:
                                        cWhite, // Set button background color to white
                                    foregroundColor:
                                        cDarkGreen, // Set text and icon color
                                    // Add other styling as needed, such as elevation, textStyle, etc.
                                  ),
                                  child: Text(
                                      "${LocaleData.basket.getString(context)}"),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    } else {
                      return Center(
                          child: Text(
                        'Такой продукт не найден',
                        style: TextStyle(color: cWhite),
                      ));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

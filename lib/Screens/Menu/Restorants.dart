import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Restoranse.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Language.dart';
import '../../Localzition/locals.dart';

class ResturansScreen extends StatefulWidget {
  @override
  _ResturansScreenState createState() => _ResturansScreenState();
}

class _ResturansScreenState extends State<ResturansScreen> {
  final sliderController = CarouselController();

  List restoranPhoneNumber = [
    '+99877 120-24-24',
    '+99877 121-24-24',
    '+99877 079-24-24'
  ];
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cDarkGreen,
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cWhite,
        ),
        title: Text(
          "${LocaleData.restaurants.getString(context)}",
          style: TextStyle(
            fontSize: 25,
            color: cWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        color: cDarkGreen,
        child: SafeArea(
          child: Column(
            children: [
              CarouselSlider.builder(
                carouselController: sliderController,
                options: CarouselOptions(
                  height: 500.h,
                  enableInfiniteScroll: false,
                  // enlargeCenterPage: true,
                ),
                itemCount: cRestoanInfo.length,
                itemBuilder: (context, index, realIndex) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    padding: EdgeInsets.fromLTRB(21.w, 22.h, 21.w, 5.h),
                    decoration: BoxDecoration(
                      color: cWhite,
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 240.w,
                          height: 159.h,
                          child: Image.asset(
                            cRestoanInfo[index]['restaurantPhoto'],
                            // fit: BoxFit.fill,
                          ),
                        ),
                        SizedBox(
                          height: 19.h,
                        ),
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Language.getLanguage() == 'ru'
                                    ? cRestoanInfo[index]['nameRU']
                                    : cRestoanInfo[index]['nameUZ'],
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w600,
                                  color: cDarkGreen,
                                ),
                              ),
                              SizedBox(
                                height: 8.h,
                              ),
                              // Text("Улица Авиасозлар дом №20",
                              //     style: TextStyle(
                              //       fontSize: 13.sp,
                              //       fontWeight: FontWeight.w400,
                              //     )),
                              SizedBox(
                                height: 8.h,
                              ),
                              TextButton(
                                onPressed: () async {
                                  final Uri url = Uri(
                                    scheme: 'tel',
                                    path: restoranPhoneNumber[index],
                                  );

                                  try {
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    } else {
                                      print('Could not launch $url');
                                    }
                                  } catch (e) {
                                    print('Error launching $url: $e');
                                  }
                                },
                                child: Text(
                                  "📞: ${restoranPhoneNumber[index]}",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 8.h,
                              ),
                              // SizedBox(
                              //   height: 8.h,
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 8.h,
                        ),
                        Spacer(),
                        SizedBox(
                          width: 253.w,
                          height: 118.h,
                          child: Image.asset(
                            cRestoanInfo[index]['photo'],
                          ),
                        ),
                        SizedBox(
                          height: 6.h,
                        ),
                        Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: Link(
                            target: LinkTarget.blank,
                            uri: Uri.parse(cRestoanInfo[index]['link']),
                            builder: (BuildContext context,
                                    Future<void> Function()? followLink) =>
                                ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cDarkGreen, // Button color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: followLink,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 0),
                                child: Text(
                                  '${LocaleData.share.getString(context)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    // fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Spacer(),
              // Container(
              //   decoration: BoxDecoration(
              //     image: DecorationImage(
              //       //"assets/images/discount.jpg",
              //       // Image.asset is used for images in your assets folder
              //       image: AssetImage("assets/images/discount.jpg"),
              //       // Cover the entire container space
              //       fit: BoxFit.cover,
              //     ),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   width: 335.w,
              //   height: 150.h,
              //   child: Container(
              //     margin: EdgeInsets.only(left: 15.w),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Text(
              //           "Новые акции",
              //           style: TextStyle(
              //             fontSize: 25,
              //             fontWeight: FontWeight.w600,
              //             color: cWhite,
              //           ),
              //         ),
              //         Text(
              //           "Акции, новинкискидки.",
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.w400,
              //             color: cWhite,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

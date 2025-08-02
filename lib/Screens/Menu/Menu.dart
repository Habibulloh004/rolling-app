import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';
import 'package:sushi_alpha_project/Screens/Menu/Products.dart';
import 'package:sushi_alpha_project/Screens/Menu/Seorch.dart';
import 'package:sushi_alpha_project/Screens/Navigation/NavBar.dart';
import 'package:upgrader/upgrader.dart';

import '../../Backend/Api.dart';
import '../../Consts/Functions.dart';
import '../../LocalMemory/CreditCard.dart';
import '../../Localzition/locals.dart';
import '../../Models/Categories.dart';
import '../Mailinglist/Mailing_List.dart';
import '../Order/Basket.dart';
import '../Profile/History.dart';

class MenuScreen extends StatefulWidget {
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  double screenHight = 0.6;

  @override
  Widget build(BuildContext context) {
    CreditCard.clearUserChoseCard();
    Size size = MediaQuery.of(context).size;

    @override
    void initState() {
      super.initState();
    }

    return Scaffold(
      drawer: NavBarScreen(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(
              Icons.menu,
              color: cWhite,
              size: 35,
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Get.to(() => SeorchScreen());
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(
              color: cWhite,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_outlined,
                  size: 21,
                  color: cDarkGreen,
                ),
                SizedBox(width: 10),
                Text(LocaleData.seorch.getString(context),
                    style: TextStyle(
                      fontSize: 18,
                      color: cDarkGreen,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: cWhite,
              size: 35,
            ),
            onPressed: () {
              Get.to(() => MailingListScreen());
            },
          ),
        ],
        backgroundColor: cDarkGreen,
      ),
      body: UpgradeAlert(
        upgrader: Upgrader(),
        child: Stack(
          children: [
            SlidingUpPanel(
              body: Container(
                color: cDarkGreen,
                child: Column(
                  children: [
                    Container(
                      width: 300,
                      height: 100,
                      margin: EdgeInsets.only(top: size.height * 0.1),
                      child: SvgPicture.asset(
                        "assets/images/LogoIcon.svg",
                      ),
                    ),
                  ],
                ),
              ),
              minHeight: size.height * 0.52,
              maxHeight: size.height - 130,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              panelBuilder: (controller) => PanelWidget(controller: controller),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: size.width,
                padding: EdgeInsets.fromLTRB(21.w, 2.h, 21.w, 20.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => HistoryScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 45.w, vertical: 8.h),
                        backgroundColor: cDarkGreen,
                        foregroundColor: cWhite,
                      ),
                      child: Text(LocaleData.orders.getString(context)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => BasketScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 45.w, vertical: 8.h),
                        backgroundColor: cDarkGreen,
                        foregroundColor: cWhite,
                      ),
                      child: Text(LocaleData.basket.getString(context)),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PanelWidget extends StatefulWidget {
  final ScrollController controller;
  PanelWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<PanelWidget> createState() => _PanelWidgetState();
}

class _PanelWidgetState extends State<PanelWidget> {
  late Future<List<Categories>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = Api.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: 12.h),
        _buildHandle(),
        SizedBox(height: 12.h),
        _buildTitle(),
        SizedBox(height: 25.h),
        _buildCategories(),
        SizedBox(height: size.height * 0.06),
      ],
    );
  }

  Widget _buildHandle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cGray,
            borderRadius: BorderRadius.circular(20.0),
          ),
          width: 32.w,
          height: 4.h,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleData.category.getString(context),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return FutureBuilder<List<Categories>>(
      future: _categories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0.w,
                mainAxisSpacing: 4.0.h,
                childAspectRatio: (81.w / (85.h + 10.h + 15.sp)),
              ),
              itemBuilder: (context, index) {
                Categories category = snapshot.data![index];
                return _buildCategoryItem(category);
              },
            ),
          );
        } else {
          return Center(
            child: Text(
              "No data available",
              style: TextStyle(color: cDarkGreen, fontSize: 18.sp),
            ),
          );
        }
      },
    );
  }

  Widget _buildShimmerLoader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0.w,
          mainAxisSpacing: 4.0.h,
          childAspectRatio: (81.w / (85.h + 10.h + 15.sp)),
        ),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 88.w,
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                          20), // Adjust the radius as needed
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    width: 50.w,
                    height: 15.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                          20), // Adjust the radius as needed
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Categories category) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductsScreen(),
            arguments: [category.categoryId, category.name]);
      },
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 81.w,
              height: 85.h,
              child: cImage(
                name: category.photo,
              ),
            ),
            SizedBox(height: 5.h),
            Text(splitText(category.name),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../Bonus.dart';
import '../FeedBack/Media.dart';
import '../Map/Locations.dart';
import '../Menu/Favorits.dart';
import '../Menu/Restorants.dart';
import '../Profile/Profile.dart';

class NavBarScreen extends StatefulWidget {
  const NavBarScreen({super.key});

  @override
  State<NavBarScreen> createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {
  String text = User.isKeyAvalible('name') ? User.getUserInfo("name") : "";

  @override
  Widget build(BuildContext context) {
    String name = text.replaceAll(' ', '\n');
    Size size = MediaQuery.of(context).size;
    return Drawer(
      // Other properties...
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/images/panel.svg',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerTheme:
                            const DividerThemeData(color: Colors.transparent),
                      ),
                      child: DrawerHeader(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(
                                20.0), // Adjust the radius as needed
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 10,
                              offset: Offset(10, 10),
                              spreadRadius: 5,
                            )
                          ],
                          color: Color(0xff196857),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 180.w,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                // 65 / 72
                                width: 62,
                                height: 70.22,
                                child: SvgPicture.asset(
                                  'assets/images/Profile.svg',
                                  fit: BoxFit.cover,
                                ),
                              )
                              //Icon
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: size.width * 0.08),
                      child: Column(
                        children: [
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/Icons/Profile.svg',
                            ),
                            title: Text(
                              LocaleData.myprofile
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => ProfileScreen())},
                          ),
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/Icons/Setting.svg',
                            ),
                            title: Text(
                              LocaleData.favorites
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => FavoritsScreen())},
                          ),
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/Icons/Location.svg',
                            ),
                            title: Text(
                              LocaleData.restaurants
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => ResturansScreen())},
                          ),
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/Icons/Wallet.svg',
                            ),
                            title: Text(
                              LocaleData.bonuses
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => BonusScreen())},
                          ),
                          ListTile(
                            leading: Container(
                                width: 20.w,
                                height: 20.h,
                                child: Image.asset('assets/Icons/address.png')),
                            title: Text(
                              LocaleData.myaddresses
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => LocationsScreen())},
                          ),
                          ListTile(
                            leading: SvgPicture.asset(
                              'assets/Icons/Message.svg',
                            ),
                            title: Text(
                              LocaleData.feedback
                                  .getString(context)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => {Get.to(() => MediaScreen())},
                          ),
                          // ListTile(
                          //   leading: SvgPicture.asset(
                          //     'assets/icons/Group.svg',
                          //   ),
                          //   title: Text(
                          //     'Выйти из аккаунта',
                          //     style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 13,
                          //       fontFamily: 'Poppins',
                          //       fontWeight: FontWeight.w400,
                          //     ),
                          //   ),
                          //   onTap: () => {
                          //     clearBoxes(),
                          //     Get.offAll(() => MenuScreen())
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: size.height * 0.05),
                width: 200,
                height: 100,
                child: SvgPicture.asset(
                  "assets/images/LogoIcon.svg",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';

import '../Backend/Api.dart';
import '../LocalMemory/User.dart';
import '../Localzition/locals.dart';

class BonusScreen extends StatelessWidget {
  const BonusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: cAppBarTittle(text: '${LocaleData.bonuses.getString(context)}'),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.1),
                Container(
                  width: size.width * 0.7,
                  height: size.height * 0.32,
                  child: SvgPicture.asset(
                    "assets/images/money.svg", // Specify the path to your SVG asset
                    fit: BoxFit
                        .fitHeight, // This will cover the entire container without stretching the image
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                FutureBuilder(
                  future: Api.getUserBonus(), // Replace with your future method
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Загрузка...",
                          style: TextStyle(color: cDarkGreen));
                    } else if (snapshot.hasError) {
                      return Text("Ошибка: ${snapshot.error}",
                          style: TextStyle(color: Colors.white));
                    } else {
                      return Text(
                        User.isUserExists() == false
                            ? snapshot.data['string'] == "что-то пошло не так"
                                ? "Error"
                                : " ${LocaleData.availablebonuses.getString(context)} ${snapshot.data['string']} ${LocaleData.som.getString(context)}"
                            : "${LocaleData.youdonnothaveaccount.getString(context)}",
                        style: TextStyle(
                          fontSize: 17,
                          color: cDarkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                FutureBuilder(
                  future: Api.getClient(
                      User.getUserInfo("phone"),
                      User.getUserInfo(
                          "password")), // Replace with your future method
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Загрузка...",
                          style: TextStyle(color: cDarkGreen));
                    } else if (snapshot.hasError) {
                      return Text("Ошибка: ${snapshot.error}",
                          style: TextStyle(color: Colors.white));
                    } else {
                      print(snapshot.data);

                      int data = int.parse(snapshot.data);

                      if (data >= 10) {
                        return SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xffBF953F),
                                  Color(0xffFCF6BA),
                                  Color(0xffB38728),
                                  /*Color(0xffFBF5B7),
                                Color(0xffAA771C),*/
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [Text("Gold"), Text("30%")],
                            ),
                          ),
                        );
                      } else if (data >= 5 && data <= 9) {
                        return SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xffa8a9ad),
                                  Color(0xffB4b5b8),
                                  Color(0xffC0c0c3),
                                  Color(0xffcbcccd),
                                  Color(0xffd7d7d8),
                                  Color(0xffe3e3e3),
                                  /*Color(0xffFBF5B7),
                                Color(0xffAA771C),*/
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [Text("Silver"), Text("20%")],
                            ),
                          ),
                        );
                        //length > 0 && length <= 4
                      } else if (data > 0 && data <= 4) {
                        return SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xff6e3a06),
                                  Color(0xff864b11),
                                  Color(0xff9e5d1c),
                                  Color(0xffB56e26),
                                  Color(0xffCd7f31),
                                  /*Color(0xffFBF5B7),
                                Color(0xffAA771C),*/
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [Text("Bronze"), Text("10%")],
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [Text(""), Text("")],
                          ),
                        ),
                      );
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

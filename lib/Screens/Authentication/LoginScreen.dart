import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Functions.dart';
import 'package:sushi_alpha_project/Screens/Authentication/OTPScreen.dart';

import '../../Backend/Api.dart';
import '../../Consts/Colors.dart';
import '../../LocalMemory/Language.dart';
import '../../LocalMemory/Location.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../Map/map_screen.dart';
import '../Order/PaymentAndLocation.dart';
import 'RegistrationScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool passwordType = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: A,
      body: Stack(
        // Use Stack to layer your SVG background and content
        children: <Widget>[
          // SVG Background
          Positioned.fill(
            child: SvgPicture.asset(
              "assets/images/background2.svg", // Specify the path to your SVG asset
              fit: BoxFit
                  .cover, // This will cover the entire container without stretching the image
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 42),
                          // Image.asset(
                          //   "assets/images/logo.png", // Path to your PNG logo
                          //   width: 250, // Specify the width of the logo
                          //   height: 200, // Specify the height of the logo
                          // ),
                          Container(
                            width: 300,
                            height: 100,
                            child: SvgPicture.asset(
                              "assets/images/LogoIcon.svg",
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Card(
                                surfaceTintColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 4.0,
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${LocaleData.login.getString(context)}',
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: cDarkGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: phoneController,
                                        decoration: InputDecoration(
                                          prefix: Text("+998"),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: cGray, // Border color
                                              width: 2.0, // Border width
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Border radius
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 2.0, // Border width
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Border radius
                                          ),
                                          labelText:
                                          '${LocaleData.phonenumber.getString(context)}',
                                          prefixIcon: Icon(
                                            Icons.phone,
                                            color: cBlack,
                                          ),
                                          labelStyle: TextStyle(color: cBlack),
                                        ),
                                        keyboardType: TextInputType.phone,
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: passwordController,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: cGray, // Border color
                                              width: 2.0, // Border width
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Border radius
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 2.0, // Border width
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Border radius
                                          ),
                                          filled: true,
                                          fillColor: cGray,
                                          labelText:
                                          '${LocaleData.password.getString(context)}',
                                          prefixIcon: Icon(
                                            Icons.lock,
                                            color: cBlack,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.visibility_off,
                                              color: cBlack,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                passwordType = !passwordType;
                                              });
                                            },
                                          ),
                                          labelStyle: TextStyle(color: cBlack),
                                        ),
                                        obscureText: passwordType,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            final pattern =
                                                r'^\+998[012345789]\d{8}$';
                                            final regExp = RegExp(pattern);

                                            if (!regExp.hasMatch("+998" +
                                                phoneController.text)) {
                                              // If phone number doesn't match the pattern, show Get.snackbar
                                              Get.snackbar(
                                                '${LocaleData.wrongphonenumber.getString(context)}', // title
                                                '12', // message
                                                snackPosition: SnackPosition
                                                    .BOTTOM, // Display at the bottom
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                              );
                                              Navigator.pop(context);
                                            } else {
                                              String code =
                                              cGenerateRandomNumbers();
                                              Api.sendSms(
                                                  code,
                                                  "+998" +
                                                      phoneController.text);
                                              Map data = {
                                                'from': 'login',
                                                'code': code,
                                                'phone': "+998" +
                                                    phoneController.text,
                                              };

                                              Get.to(() => OTPScreen(),
                                                  arguments: data);
                                            }
                                          },
                                          child: Text(
                                            '${LocaleData.forgotyourpassword.getString(context)}',
                                            style: TextStyle(color: cBlack),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            cDarkGreen, // Button color
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(15),
                                            ),
                                          ),
                                          onPressed: () async {
                                            showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) {
                                                  return Center(
                                                    child:
                                                    CircularProgressIndicator(
                                                      color: cDarkGreen,
                                                    ),
                                                  );
                                                });

                                            final pattern =
                                                r'^\+998[012345789]\d{8}$';
                                            final regExp = RegExp(pattern);

                                            if (!regExp.hasMatch("+998" +
                                                phoneController.text) ||
                                                passwordController.text == "") {
                                              // If phone number doesn't match the pattern, show Get.snackbar
                                              Get.snackbar(
                                                '${LocaleData.wrongphonenumber.getString(context)}', // title
                                                '1', // message
                                                snackPosition: SnackPosition
                                                    .BOTTOM, // Display at the bottom
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                              );
                                              Navigator.pop(context);
                                            } else {
                                              Map<dynamic, dynamic> info =
                                              await Api.getClient(
                                                  "+998" +
                                                      phoneController.text,
                                                  passwordController.text);
                                              print(info);

                                              List genderList =
                                              getGendersForLanguage(
                                                  Language.getLanguage());
                                              String sex = genderList[int.parse(
                                                  info['client_sex'])];

                                              print(sex);

                                              if (info['res'] == true) {
                                                User.addUserInfo(
                                                    "name", info['name']);
                                                User.addUserInfo(
                                                    "phone", info['phone']);
                                                User.addUserInfo(
                                                    "id", info['id']);
                                                User.addUserInfo("password",
                                                    info['password']);
                                                User.addUserInfo(
                                                    "client_sex", sex);
                                                User.addUserInfo("birthday",
                                                    info['birthday']);

                                                // Navigator.pop(context);
                                                if (MapLocation.isNoMaps()) {
                                                  Get.offAll(() => MapScreen(),
                                                      arguments: {
                                                        'action': 'add'
                                                      });
                                                } else {
                                                  Get.offAll(() =>
                                                      PaymentAndLocationScreen());
                                                }
                                              } else {
                                                Get.snackbar(
                                                  info['message'], // title
                                                  '', // message
                                                  snackPosition: SnackPosition
                                                      .BOTTOM, // Display at the bottom
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                              }
                                              // Navigator.pop(context);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            child: Text(
                                              '${LocaleData.login.getString(context)}',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  //areyouherefirsttime
                                  '${LocaleData.areyouherefirsttime.getString(context)}',
                                  style: TextStyle(
                                    color: cBlack,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.to(() => RegistrationScreen());
                                  },
                                  child: Text(
                                    '${LocaleData.registration.getString(context)}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: cDarkGreen,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
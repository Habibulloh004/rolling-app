import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sushi_alpha_project/Backend/Api.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Functions.dart';
import '../../LocalMemory/Location.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../Map/map_screen.dart';
import '../Order/PaymentAndLocation.dart';

class OTPScreen extends StatefulWidget {
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late Map userData = Get.arguments;
  String otpCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                        textAlign: TextAlign.center,
                                        '${LocaleData.enterverificationcode.getString(context)}',
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: cDarkGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Container(
                                        width: 200,
                                        child: Text(
                                          '${LocaleData.smssenttothesamephonenumber.getString(context)} ${userData['phone']}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF636363),
                                            fontSize: 14,
                                            fontFamily: 'SF Pro',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Container(
                                        width: 250,
                                        child: PinCodeTextField(
                                          keyboardType: TextInputType.number,
                                          appContext: context,
                                          length: 4, // The length of the OTP
                                          onChanged: (String value) {
                                            // otpCode = value;
                                          },
                                          onCompleted: (String value) {
                                            // Code to execute after the OTP is entered
                                            otpCode = value;
                                          },
                                          pinTheme: PinTheme(
                                            shape: PinCodeFieldShape.box,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            activeColor: cBlack,
                                            inactiveColor: cBlack,
                                            fieldHeight: 50,
                                            fieldWidth: 40,
                                            activeFillColor: Colors.white,
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
                                            // login
                                            if (userData['from'] == 'login') {
                                              if (otpCode == userData['code']) {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: cDarkGreen,
                                                        ),
                                                      );
                                                    });

                                                Map<dynamic, dynamic> info =
                                                    await Api.getClientOtp(
                                                        userData['phone']);

                                                User.addUserInfo(
                                                    "name", info['name']);
                                                User.addUserInfo(
                                                    "phone", info['phone']);
                                                User.addUserInfo(
                                                    "id", info['id']);
                                                User.addUserInfo("password",
                                                    info['password']);

                                                Navigator.pop(context);
                                                if (MapLocation.isNoMaps()) {
                                                  Get.off(() => MapScreen(),
                                                      arguments: {
                                                        'action': 'add'
                                                      });
                                                } else {
                                                  Get.off(() =>
                                                      PaymentAndLocationScreen());
                                                }
                                              } else {
                                                Get.snackbar(
                                                  '${LocaleData.incorrectcode.getString(context)}', // title
                                                  '', // message
                                                  snackPosition: SnackPosition
                                                      .BOTTOM, // Display at the bottom
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                              }
                                            }

                                            if (userData['from'] ==
                                                'register') {
                                              print("-------");
                                              print(otpCode);
                                              print(userData['code']);

                                              if (otpCode == userData['code']) {
                                                print("Password correct");
                                                Map password = {
                                                  'password':
                                                      "password ${userData['password']}",
                                                  'length': '0',
                                                };

                                                String json =
                                                    jsonEncode(password);

                                                Map data = {
                                                  'client_name':
                                                      userData['name'],
                                                  'phone': userData['phone'],
                                                  'comment': json,
                                                  'birthday':
                                                      userData['birthday'],
                                                  'client_sex':
                                                      userData['client_sex'],
                                                  'client_groups_id_client':
                                                      '5',
                                                };

                                                Map<dynamic, dynamic> info =
                                                    await Api.createClient(
                                                        data);
                                                print(info);

                                                if (info['res'] == true) {
                                                  User.addUserInfo(
                                                      "name", userData['name']);
                                                  User.addUserInfo("phone",
                                                      userData['phone']);
                                                  User.addUserInfo("id",
                                                      info['id'].toString());
                                                  User.addUserInfo("password",
                                                      userData['password']);
                                                  User.addUserInfo("birthday",
                                                      userData['birthday']);

                                                  ///
                                                  ///
                                                  String localeLang =
                                                      Localizations.localeOf(
                                                              context)
                                                          .languageCode;
                                                  List genders =
                                                      getGendersForLanguage(
                                                          localeLang);
                                                  User.addUserInfo(
                                                      "client_sex",
                                                      genders[userData[
                                                          'client_sex']]);

                                                  if (MapLocation.isNoMaps()) {
                                                    Get.offAll(
                                                        () => MapScreen(),
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
                                              } else {
                                                Get.snackbar(
                                                  '${LocaleData.incorrectcode.getString(context)}', // title
                                                  '', // message
                                                  snackPosition: SnackPosition
                                                      .BOTTOM, // Display at the bottom
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                              }
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            child: Text(
                                              '${LocaleData.confirm.getString(context)}',
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

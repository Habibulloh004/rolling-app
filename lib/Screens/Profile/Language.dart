import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/LocalMemory/MaillingList.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Functions.dart';
import '../../LocalMemory/Language.dart';
import '../../LocalMemory/User.dart';
import '../Dicount/Discount.dart';
import '../Menu/Menu.dart';

class LanguageScreen extends StatefulWidget {
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late FlutterLocalization _flutterLocalization;

  @override
  void initState() {
    super.initState();
    _flutterLocalization = FlutterLocalization.instance;
  }

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
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 60, vertical: 30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        "",
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: cDarkGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0.0, // No elevation
                                          ),
                                          onPressed: () async {
                                            _flutterLocalization
                                                .translate("ru");

                                            bool subscribed =
                                                Maillinglist.isUserSubscribed();

                                            if (User.isUserExistsStrict()) {
                                              Language.setLanguage('ru');
                                              Get.offAll(
                                                  () => DiscountScreen());
                                            } else if (!subscribed) {
                                              Language.setLanguage('en');
                                              Get.offAll(() => MenuScreen());
                                            } else {
                                              Language.setLanguage('ru');
                                              Navigator.pop(context);
                                            }

                                            unsubscribeFromAllTopics();
                                            await FirebaseMessaging.instance
                                                .subscribeToTopic(
                                                    "all_users_ru");
                                            Maillinglist.subscribe(
                                                "all_users_ri");
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                '🇷🇺',
                                                style: TextStyle(
                                                  fontSize: 30,
                                                ),
                                              ),
                                              Text(
                                                " Русский",
                                                style: TextStyle(
                                                  color: cBlack,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          )),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0.0, // No elevation
                                          ),
                                          onPressed: () async {
                                            _flutterLocalization
                                                .translate("en");

                                            bool subscribed =
                                                Maillinglist.isUserSubscribed();

                                            if (User.isUserExistsStrict()) {
                                              Language.setLanguage('en');
                                              Get.offAll(
                                                  () => DiscountScreen());
                                            } else if (!subscribed) {
                                              Language.setLanguage('en');
                                              Get.offAll(() => MenuScreen());
                                            } else {
                                              Language.setLanguage('en');
                                              Navigator.pop(context);
                                            }

                                            unsubscribeFromAllTopics();
                                            await FirebaseMessaging.instance
                                                .subscribeToTopic(
                                                    "all_users_en");
                                            Maillinglist.subscribe(
                                                "all_users_en");
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                '🇺🇸',
                                                style: TextStyle(
                                                  fontSize: 30,
                                                ),
                                              ),
                                              Text(
                                                " English",
                                                style: TextStyle(
                                                  color: cBlack,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          )),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0.0, // No elevation
                                          ),
                                          onPressed: () async {
                                            _flutterLocalization
                                                .translate("uz");

                                            bool subscribed =
                                                Maillinglist.isUserSubscribed();

                                            if (User.isUserExistsStrict()) {
                                              Language.setLanguage('uz');
                                              Get.offAll(
                                                  () => DiscountScreen());
                                            } else if (!subscribed) {
                                              Language.setLanguage('en');
                                              Get.offAll(() => MenuScreen());
                                            } else {
                                              Language.setLanguage('uz');
                                              Navigator.pop(context);
                                            }

                                            //"all_users_uz
                                            unsubscribeFromAllTopics();
                                            await FirebaseMessaging.instance
                                                .subscribeToTopic(
                                                    "all_users_uz");
                                            Maillinglist.subscribe(
                                                "all_users_uz");
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                '🇺🇿',
                                                style: TextStyle(
                                                  fontSize: 30,
                                                ),
                                              ),
                                              Text(
                                                " O'zbek",
                                                style: TextStyle(
                                                  color: cBlack,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          )),
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

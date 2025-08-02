import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/LocalMemory/Order.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Consts/Widgets.dart';

class MediaScreen extends StatefulWidget {
  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(Order.getOrderLength());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: cAppBarTittle(text: 'Обратная связь'),
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.navigate_before,
              color: cDarkGreen,
              size: 30,
            )),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 53),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 174,
                      height: 174,
                      child: Image.asset("assets/images/feedback.png"),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Text("Мы в Соц. сетях",
                        style: TextStyle(
                          fontSize: 18,
                          color: cDarkGreen,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {
                              launchUrl(Uri.parse(
                                  'https://www.instagram.com/rollingsushiuz'));
                              // claunchURL('https://www.instagram.com/rollingsushiuz');
                            },
                            icon: Icon(FontAwesomeIcons.instagram,
                                color: cDarkGreen, size: 40)),
                        IconButton(
                            onPressed: () {
                              launchUrl(Uri.parse(
                                  'https://www.facebook.com/share/AWGgNk6838gCPzwP/?mibextid=LQQJ4d'));
                            },
                            icon: Icon(FontAwesomeIcons.facebook,
                                color: cDarkGreen, size: 40)),
                        IconButton(
                            onPressed: () {
                              claunchURL("https://t.me/rollingsushiuz");
                            },
                            icon: Icon(FontAwesomeIcons.telegram,
                                color: cDarkGreen, size: 40)),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                  ],
                ),
              )),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: cDarkGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // Stretch the column to the width of the screen/container
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      "Если у вас есть вопросы и/или предложения",
                      style: TextStyle(
                        fontSize: 18,
                        color: cWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      textAlign: TextAlign.center,
                      "Отправьте письмо на почту",
                      style: TextStyle(
                        fontSize: 15,
                        color: cWhite,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () async {
                        final Uri url = Uri(
                          scheme: 'mailto',
                          path: "rollingsushiuz@gmail.com",
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
                        "rollingsushiuz@gmail.com",
                        style: TextStyle(
                          fontSize: 15,
                          color: cWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    Spacer(),
                    // Space between the buttons
                    ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri(
                          scheme: 'tel',
                          path: "+998771244444",
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: cBlack,
                        backgroundColor: cWhite, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Text('+998 77 124 44 44',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

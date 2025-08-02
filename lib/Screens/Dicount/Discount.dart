import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/LocalMemory/Language.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Consts/Colors.dart';
import '../../Localzition/locals.dart';

class DiscountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: cDarkGreen,
        child: Stack(
          children: [
            Positioned.fill(
                child: Image.asset(
              "assets/images/sushi-${Language.getLanguage()}.jpg",
              fit: BoxFit.contain,
            )),
            Positioned(
                bottom: 50,
                left: size.height * 0.08,
                child: Container(
                  width: size.width * 0.65,
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(cDarkGreen),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10.0), // Rounded corners
                        ),
                      ),
                    ),
                    onPressed: () {
                      Get.offAll(() => MenuScreen());
                    },
                    child: Text("${LocaleData.confirm.getString(context)}",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

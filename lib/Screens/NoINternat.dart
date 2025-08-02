import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../Consts/Colors.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("УПС!",
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                )),
            SizedBox(height: size.height * 0.05),
            Container(
              child: Image.asset(
                "assets/images/noInternet.png",
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                  textAlign: TextAlign.center,
                  "Мы потеряли соединение с вашим интернетом",
                  style: TextStyle(
                    fontSize: 28,
                    color: cDarkGreen,
                    fontWeight: FontWeight.w700,
                  )),
            )
          ],
        ),
      ),
    ));
  }
}

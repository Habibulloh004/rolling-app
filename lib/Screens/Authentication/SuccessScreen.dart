import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../Consts/Colors.dart';

class SucesssScreen extends StatelessWidget {
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
                          // Image.asset(
                          //   "assets/images/logo.png", // Path to your PNG logo
                          //   width: 250, // Specify the width of the logo
                          //   height: 200, // Specify the height of the logo
                          // ),
                          Container(
                            width: 244,
                            height: 244,
                            child: SvgPicture.asset(
                              "assets/images/вектор.svg",
                            ),
                          ),
                          Expanded(
                            child: Card(
                              surfaceTintColor: Colors.transparent,
                              color: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 30),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Поздравляем',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontFamily: 'SF Pro',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Ваш аккаунт успешно \nсоздан!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontFamily: 'SF Pro',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cDarkGreen, // Button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () {
                                  // Implement login functionality
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  child: Text(
                                    'Начать заказ',
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

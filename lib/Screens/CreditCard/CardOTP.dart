import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../Backend/Api.dart';
import '../../Consts/Colors.dart';
import '../../Consts/Functions.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/HistoryOrder.dart';
import '../../LocalMemory/Order.dart';
import '../../Localzition/locals.dart';
import '../Order/endOfOrder.dart';

class CardOTP extends StatefulWidget {
  @override
  State<CardOTP> createState() => _CardOTPState();
}

class _CardOTPState extends State<CardOTP> {
  late Map orderData;
  late String session;
  late Map infoForNextScreen;

  // orderMapData,
  // data['session'],
  // haveDiscount,
  // bonus,

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    List userData = Get.arguments;

    if (userData.length >= 3) {
      orderData = userData[0];
      session = userData[1];
      infoForNextScreen = userData[2];
    } else {
      // Handle the case where the arguments are missing or incomplete
      print(
          'Error: Get.arguments does not have the expected number of elements.');
      Get.back(); // Go back or handle the error in an appropriate way
    }

    // orderData = userData[0];
    // session = userData[1];
    // infoForNextScreen = userData[2];
  }

  String otpCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cDarkGreen,
        ),
      ),
      body: Stack(
        // Use Stack to layer your SVG background and content
        children: <Widget>[
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
                                          '',
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
                                          length: 6, // The length of the OTP
                                          onChanged: (String value) {
                                            otpCode = value;
                                          },
                                          onCompleted: (String value) {
                                            // Code to execute after the OTP is entered
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

                                            //Alll cheching is happening right here
                                            Map<String, String> data = await Api
                                                .paymentConfermationCreditCard(
                                                    session, otpCode);
                                            //
                                            if (data['status'] == "success") {
                                              HapticFeedback.heavyImpact();
                                              Navigator.pop(context);
                                              Get.bottomSheet(
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 20),
                                                  height: 270.h,
                                                  color: Colors.white,
                                                  child: Center(
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                            '${LocaleData.paymentwentsuccessful.getString(context)}'),
                                                        SizedBox(
                                                          height: 20,
                                                        ),
                                                        Container(
                                                          width: 82,
                                                          height: 82,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                              border: Border.all(
                                                                  color:
                                                                      cDarkGreen,
                                                                  width: 5)),
                                                          child: Icon(
                                                            Icons.done,
                                                            size: 40,
                                                          ),
                                                        ),
                                                        Spacer(),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  cDarkGreen, // Button color
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15),
                                                              ),
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (context) {
                                                                    return const Center(
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        color:
                                                                            cDarkGreen,
                                                                      ),
                                                                    );
                                                                  });

                                                              await userUpDateGroupe();

                                                              String orderId =
                                                                  await Api
                                                                      .giveOrder(
                                                                          orderData);
                                                              if (orderId ==
                                                                  'error') {
                                                                Get.snackbar(
                                                                  "${LocaleData.somethingwentwrong.getString(context)}", // title
                                                                  '', // message
                                                                  snackPosition:
                                                                      SnackPosition
                                                                          .BOTTOM, // Display at the bottom
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  colorText:
                                                                      Colors
                                                                          .white,
                                                                );
                                                              } else {
                                                                //Order Happening

                                                                userUpDateGroupe();

                                                                Map data = {
                                                                  'id': orderId,
                                                                  'date':
                                                                      infoForNextScreen[
                                                                          'time'],
                                                                  'priceOfOrderString':
                                                                      infoForNextScreen[
                                                                          'itogo'],
                                                                  'products': Order
                                                                      .getFullOrder(),
                                                                  'payment_method':
                                                                      'card',
                                                                };

                                                                //Add order to history Localy
                                                                HistoryOrder
                                                                    .addHistoryOrder(
                                                                        data);

                                                                Get.offAll(
                                                                    () =>
                                                                        EndOFOrderScreen(),
                                                                    arguments:
                                                                        infoForNextScreen);
                                                              }
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          15),
                                                              child: Text(
                                                                '${LocaleData.confirm.getString(context)}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 17,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                isDismissible:
                                                    false, // Prevent dismissal by tapping outside
                                                enableDrag: false,
                                              );
                                            } else {
                                              Get.snackbar(
                                                "${LocaleData.somethingwentwrong.getString(context)}", // title
                                                '${LocaleData.checkyourcard.getString(context)}', // message
                                                snackPosition: SnackPosition
                                                    .BOTTOM, // Display at the bottom
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                              );

                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            }
                                            // making order will happne here
                                            // Got to end of order with all neccery arguments
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

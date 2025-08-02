import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Screens/Order/PaymentAndLocation.dart';

import '../../Consts/Colors.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/CreditCard.dart';
import '../../Localzition/locals.dart';
import '../Menu/Menu.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late String from;

  @override
  void initState() {
    super.initState();
    from = Get.arguments;
  }

  TextEditingController cardNumberController = TextEditingController();

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = 'Name of card';
  String cvvCode = '';

  OutlineInputBorder? border;
  TextEditingController bankName = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cDarkGreen,
        ),
        title: Text(
          "${LocaleData.card.getString(context)}",
          style: TextStyle(
            fontSize: 25,
            color: cDarkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                CreditCardWidget(
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  bankName: bankName.text,
                  showBackView: false,
                  obscureCardNumber: true,
                  obscureCardCvv: true,
                  isHolderNameVisible: true,
                  cardBgColor: cDarkGreen,
                  isSwipeGestureEnabled: true,
                  onCreditCardWidgetChange:
                      (CreditCardBrand creditCardBrand) {},
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  onChanged: (String text) {
                    setState(() {
                      cardHolderName = text;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the cardholder name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: cGray,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: cGray,
                    labelText: '${LocaleData.writecardname.getString(context)}',
                    labelStyle: TextStyle(
                      color: Color(0xff929DA9),
                    ),
                    hintText: "Humo",
                    hintStyle: TextStyle(
                      color: Color(0xff929DA9),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  onChanged: (String text) {
                    setState(() {
                      cardNumber = text;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the card number';
                    }
                    if (value.replaceAll(' ', '').length != 16) {
                      return 'Card number must be 16 digits';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: cGray,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: cGray,
                    labelText: '${LocaleData.cardnumber.getString(context)}',
                    labelStyle: TextStyle(
                      color: Color(0xff929DA9),
                    ),
                    hintText: "0000 0000 0000 0000",
                    hintStyle: TextStyle(
                      color: Color(0xff929DA9),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset("assets/Icons/cardIcon.svg"),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        onChanged: (String text) {
                          setState(() {
                            expiryDate = text;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the expiry date';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          CardMonthInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: cGray,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: cGray,
                          labelText:
                              '${LocaleData.validityperiod.getString(context)}',
                          labelStyle: TextStyle(
                            color: Color(0xff929DA9),
                          ),
                          hintText: "MM/YY",
                          hintStyle: TextStyle(
                            color: Color(0xff929DA9),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(child: Container()),
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cDarkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        // Save card details if all fields are valid
                        CreditCard.setCreditCardNumber(cardNumber);
                        CreditCard.setCreditCardName(cardHolderName);
                        CreditCard.setCreditCardDate(expiryDate);

                        if (from == "fromProfile") {
                          Get.offAll(() => MenuScreen());
                        } else {
                          Get.offAll(() => PaymentAndLocationScreen());
                        }
                      } else {
                        // If any field is invalid, show error message
                        Get.snackbar(
                          "${LocaleData.somethingwentwrong.getString(context)}", // title
                          '', // message
                          snackPosition:
                              SnackPosition.BOTTOM, // Display at the bottom
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String inputData = newValue.text;
    StringBuffer buffer = StringBuffer();

    for (var i = 0; i < inputData.length; i++) {
      buffer.write(inputData[i]);
      int index = i + 1;

      if (index % 4 == 0 && inputData.length != index) {
        buffer.write("  ");
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
    );
  }
}

class CardMonthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();

    for (var i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;

      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write("/");
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

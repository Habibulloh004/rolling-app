import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';

import '../../LocalMemory/CreditCard.dart';
import '../../Localzition/locals.dart';
import 'CreditCard.dart';

class Cards extends StatefulWidget {
  const Cards({super.key});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  String cardNumber = CreditCard.getCreditCardName() is String
      ? CreditCard.getCreditCardNumber()
      : " ";
  String expiryDate = CreditCard.getCreditCardName() is String
      ? CreditCard.getCreditCardDate()
      : " ";
  String cardHolderName = CreditCard.getCreditCardName() is String
      ? CreditCard.getCreditCardName()
      : " ";
  String cvvCode = '';
  bool isCvvFocused = false;
  OutlineInputBorder? border;
  TextEditingController bankName = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${LocaleData.card.getString(context)}"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              CreditCard.getCreditCardName() is String
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: cGray,
                          )),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(""),
                              IconButton(
                                onPressed: () {
                                  Get.to(
                                    () => CardScreen(),
                                    arguments: "fromProfile",
                                  );
                                },
                                icon: Icon(
                                  Icons.edit,
                                  size: 25,
                                  color: Color(0xff929DA9),
                                ),
                              )
                            ],
                          ),
                          CreditCardWidget(
                            // glassmorphismConfig: Glassmorphism.defaultConfig(),
                            cardNumber: cardNumber,
                            expiryDate: expiryDate,
                            cardHolderName: cardHolderName,
                            cvvCode: cvvCode,
                            bankName: bankName.text,
                            // frontCardBorder: Border.all(color: Colors.grey),
                            // backCardBorder: Border.all(color: Colors.grey),
                            showBackView: isCvvFocused,
                            obscureCardNumber: true,
                            obscureCardCvv: true,
                            isHolderNameVisible: true,
                            cardBgColor: cDarkGreen,
                            isSwipeGestureEnabled: true,
                            onCreditCardWidgetChange:
                                (CreditCardBrand creditCardBrand) {},
                            customCardTypeIcons: <CustomCardTypeIcon>[
                              CustomCardTypeIcon(
                                cardType: CardType.mastercard,
                                cardImage: Image.asset(
                                  'assets/images/mastercard.png',
                                  height: 48,
                                  width: 48,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: cGray,
                          )),
                      child: Column(
                        children: [
                          Text(textAlign: TextAlign.start, "Add the card"),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: cGray,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => CardScreen(),
                                  arguments: "fromProfile",
                                );
                              },
                              child: Container(
                                child: Icon(
                                  Icons.add,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

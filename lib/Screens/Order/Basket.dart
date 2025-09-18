import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/LocalMemory/Order.dart';
import 'package:sushi_alpha_project/Screens/Menu/Menu.dart';

import '../../Backend/Api.dart';
import '../../Consts/Functions.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../../Store/PromocodeStore.dart';
import '../Authentication/RegistrationScreen.dart';
import '../Promocode/PromocodeDialog.dart';
import 'BasketBonus.dart';
import 'PaymentAndLocation.dart';

class BasketScreen extends StatefulWidget {
  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  late String price;
  late String priceWithDelivery;
  late Future<int> getOrderPrice;

  // Promocode related variables
  final PromocodeStore promocodeStore = Get.find<PromocodeStore>();
  List<dynamic> promotions = [];
  List<dynamic> productsData = [];
  List<dynamic> categoriesData = [];
  bool isLoadingPromocode = false;

  // Cache delivery price
  int deliveryPriceInt = 0;

  @override
  void initState() {
    super.initState();
    getOrderPrice = Api.getDeliveryPrice();
    loadPromocodeData().then((_) {
      // Validate promocode after initialization
      if (mounted) {
        promocodeStore.validatePromocodeOnCartChange();
      }
    });
  }

  // Load promocode data
  Future<void> loadPromocodeData() async {
    setState(() {
      isLoadingPromocode = true;
    });

    try {
      final results = await Future.wait([
        Api.getPromotions(),
        Api.getAllProducts(),
        Api.getAllCategories(),
      ]);

      setState(() {
        promotions = results[0];
        productsData = results[1];
        categoriesData = results[2];
        isLoadingPromocode = false;
      });

      // Validate promocode after data loads to ensure consistency
      promocodeStore.validatePromocodeOnCartChange();

    } catch (e) {
      print('Error loading promocode data: $e');
      setState(() {
        isLoadingPromocode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${LocaleData.basket.getString(context)}'),
          leading: IconButton(
              onPressed: () {
                Get.offAll(() => MenuScreen());
              },
              icon: Icon(
                Icons.navigate_before,
                color: cDarkGreen,
                size: 30,
              )),
        ),
        body: FutureBuilder(
          future: getOrderPrice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: cGray,
                  valueColor: AlwaysStoppedAnimation<Color>(cDarkGreen),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              if (Order.isNoOrder()) {
                return Column(
                  children: [
                    Center(
                        child: Column(
                          children: [
                            SizedBox(height: 100),
                            Container(
                              width: 200,
                              height: 200,
                              child: SvgPicture.asset("assets/images/вектор.svg"),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "${LocaleData.yourbasketisempty.getString(context)}",
                              style: TextStyle(
                                fontSize: 25,
                                color: cDarkGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              width: 300,
                              child: Text(textAlign: TextAlign.center, ""),
                            ),
                          ],
                        )),
                  ],
                );
              } else {
                deliveryPriceInt = snapshot.data!;
                String deliveryPriceStr = makePriceSomString(deliveryPriceInt);

                price = Order.getOrderPrice()['string'];
                priceWithDelivery = makePriceSomString(
                    Order.getOrderPrice()['int'] + deliveryPriceInt);

                return Column(
                  children: [
                    // Yuqoridagi ro'yxat (scroll bo'ladi)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(children: basketInfo()),
                      ),
                    ),

                    // Pastki yashil panel — ichida scroll YO'Q, tugmalar pastda qoladi
                    Obx(() {
                      final hasActivePromo = promocodeStore.activePromocode.value != null;
                      const extraForPromo = 6.0; // px (~bitta qator/tugma balandligi)

                      return Container(
                        decoration: BoxDecoration(
                          color: cDarkGreen,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            topRight: Radius.circular(30.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 20,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              // Yuqori blok + qo'shimcha bo'shliq + pastki blok (confirm)
                              children: [
                                const SizedBox(height: 18),

                                // Yuqori blok (scrollsiz)
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildPriceBreakdown(context, deliveryPriceInt, deliveryPriceStr),
                                      const SizedBox(height: 12),
                                      _buildPromocodeButton(context),
                                      const SizedBox(height: 12),
                                      _buildBonusButton(context),

                                      // Promo yoqilganda faqat yashil wrapper tepaga kengayishi uchun
                                      SizedBox(height: hasActivePromo ? extraForPromo : 0),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Pastki blok — Confirm doim pastda, joyidan siljimaydi
                                _buildConfirmButton(context),
                                SizedBox(height: 10 + MediaQuery.of(context).padding.bottom),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );


                // return Column(
                //   children: [
                //     Expanded(
                //         flex: 3,
                //         child: SingleChildScrollView(
                //           child: Column(
                //             children: basketInfo(),
                //           ),
                //         )),
                //     Expanded(
                //       flex: 2,
                //       child: Container(
                //         decoration: BoxDecoration(
                //           color: cDarkGreen,
                //           borderRadius: BorderRadius.only(
                //             topLeft: Radius.circular(30.0),
                //             topRight: Radius.circular(30.0),
                //           ),
                //         ),
                //         child: Container(
                //           padding: EdgeInsets.symmetric(horizontal: 30.w),
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.stretch,
                //             children: [
                //               SizedBox(height: 25.h),
                //               _buildPriceBreakdown(context, deliveryPriceInt, deliveryPriceStr),
                //               SizedBox(height: 24.h),
                //               _buildPromocodeButton(context),
                //               SizedBox(height: 12.h),
                //               _buildBonusButton(context),
                //               Spacer(),
                //               _buildConfirmButton(context),
                //               Spacer(),
                //             ],
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // );
              }
            } else {
              return Text('No data available');
            }
          },
        ));
  }

  Widget _buildPriceBreakdown(
      BuildContext context,
      int deliveryPriceInt,
      String deliveryPriceStr,
      ) {
    return Obx(() {
      final orderPriceInt = Order.getOrderPrice()['int'] ?? 0;
      final promocodeDiscount = promocodeStore.getTotalDiscount();
      final promocodePrice = promocodeStore.promocodePrice.value;

      double finalPrice = orderPriceInt.toDouble() + deliveryPriceInt;

      // Apply promocode discount - matching JSX logic
      if (promocodePrice > 0) {
        finalPrice -= promocodePrice;
      } else if (promocodeDiscount > 0) {
        // Apply percentage discount only to order price, not delivery
        double discountAmount = orderPriceInt * (promocodeDiscount / 100);
        finalPrice = orderPriceInt - discountAmount + deliveryPriceInt;
      }

      // Ensure price doesn't go below delivery cost
      finalPrice = finalPrice.clamp(deliveryPriceInt.toDouble(), double.infinity);

      return Column(
        children: [
          // Products row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LocaleData.products.getString(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: cWhite,
                    fontWeight: FontWeight.w400,
                  )),
              Text(
                  "${price} ${LocaleData.som.getString(context)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: cWhite,
                    fontWeight: FontWeight.w400,
                  ))
            ],
          ),
          SizedBox(height: 20.h),

          // Promocode discount row
          if (promocodePrice > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Промокод',
                    style: TextStyle(
                      fontSize: 12,
                      color: cWhite,
                      fontWeight: FontWeight.w400,
                    )),
                Text(
                    "-${makePriceSomString(promocodePrice.toInt())} ${LocaleData.som.getString(context)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade200,
                      fontWeight: FontWeight.w400,
                    ))
              ],
            ),
            SizedBox(height: 20.h),
          ],

          if (promocodeDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Промокод',
                    style: TextStyle(
                      fontSize: 12,
                      color: cWhite,
                      fontWeight: FontWeight.w400,
                    )),
                Text(
                    "${promocodeDiscount.toStringAsFixed(0)}% скидка",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade200,
                      fontWeight: FontWeight.w400,
                    ))
              ],
            ),
            SizedBox(height: 20.h),
          ],

          // Delivery row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LocaleData.delivery.getString(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: cWhite,
                    fontWeight: FontWeight.w400,
                  )),
              Text(
                  "${deliveryPriceStr} ${LocaleData.som.getString(context)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: cWhite,
                    fontWeight: FontWeight.w400,
                  ))
            ],
          ),
          SizedBox(height: 20.h),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleData.total.getString(context),
                style: TextStyle(
                  fontSize: 17,
                  color: cWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Show original price with strikethrough if promocode is active
                  if (promocodeStore.activePromocode.value != null &&
                      (promocodePrice > 0 || promocodeDiscount > 0))
                    Text(
                      "${priceWithDelivery} ${LocaleData.som.getString(context)}",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  // Final price
                  Text(
                    "${makePriceSomString(finalPrice.toInt())} ${LocaleData.som.getString(context)}",
                    style: TextStyle(
                      color: cWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPromocodeButton(BuildContext context) {
    return Obx(() {
      final hasActivePromo = promocodeStore.activePromocode.value != null;

      return ElevatedButton(
        onPressed: isLoadingPromocode
            ? null
            : () async {
          final result = await showDialog<String>(
            context: context,
            barrierDismissible: true,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: PromocodeDialog(
                promotions: promotions,
                productsData: productsData,
                categoriesData: categoriesData,
              ),
            ),
          );

          if (result == 'applied' || result == 'removed') {
            setState(() {
              _updatePrices();
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: hasActivePromo ? Colors.green.shade600 : cWhite,
          foregroundColor: hasActivePromo ? cWhite : cBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasActivePromo ? Icons.check_circle : Icons.local_offer,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                hasActivePromo
                    ? 'Промокод активен'
                    : 'Применить промокод',
                style: TextStyle(fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBonusButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (User.isUserExists()) {
          Get.to(() => RegistrationScreen());
        } else {
          Get.to(() => BasketBonusScreen());
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: cBlack,
        backgroundColor: cWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Text(LocaleData.usebonus.getString(context),
            style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (User.isUserExists()) {
          Get.to(() => RegistrationScreen());
        } else {
          Get.to(() => PaymentAndLocationScreen(), arguments: {
            'promocode': promocodeStore.activePromocode.value,
            'promocodeDiscount': promocodeStore.getTotalDiscount(),
            'promocodePrice': promocodeStore.promocodePrice.value,
          });
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: cBlack,
        backgroundColor: cWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Text(LocaleData.confirm.getString(context),
            style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }

  void _updatePrices() {
    try {
      price = Order.getOrderPrice()['string'] ?? '0';
      priceWithDelivery = makePriceSomString(
        (Order.getOrderPrice()['int'] ?? 0) + deliveryPriceInt,
      );

      // Always validate promocode whenever prices update
      promocodeStore.validatePromocodeOnCartChange();

    } catch (e) {
      print('Error updating prices: $e');
      // Fallback values
      price = '0';
      priceWithDelivery = makePriceSomString(deliveryPriceInt);
    }
  }

  List<Widget> basketInfo() {
    List<Widget> result = [];

    result = List.generate(
      Order.getOrderLength(),
          (index) {
        final orderItem = Order.getOrderAt(index);
        final isPromoItem = orderItem['promocode'] == true;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(),
          child: Row(
            children: [
              //image
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                margin: EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 90.w,
                      height: 90.h,
                      child: InstaImageViewer(
                        child: cImage(
                          name: orderItem['photo'] ?? '',
                        ),
                      ),
                    ),
                    if (isPromoItem)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isPromoItem
                              ? "Бесплатно"
                              : "${orderItem['price'] ?? '0'} ${LocaleData.som.getString(context)}",
                          style: TextStyle(
                            fontSize: 17.sp,
                            color: isPromoItem ? Colors.green : cDarkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isPromoItem) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Бонус',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      orderItem['name'] ?? '',
                      style: TextStyle(
                        fontSize: 17,
                        color: cDarkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                        '${orderItem['amount'] ?? '1'} ${LocaleData.pc.getString(context)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cDarkGreen,
                          fontWeight: FontWeight.w400,
                        )),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!isPromoItem) // Only show controls for non-promo items
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  child: Container(
                                    width: 24.w,
                                    height: 20.h,
                                    child: IconButton(
                                      icon: Icon(Icons.remove, size: 14),
                                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                      onPressed: () {
                                        setState(() {
                                          int amount = int.parse(orderItem['amount'] ?? '1');
                                          amount -= 1;

                                          if (amount >= 1) {
                                            orderItem['amount'] = '$amount';
                                            // Validate promocode when quantity changes
                                            promocodeStore.validatePromocodeOnCartChange();
                                          } else if (Order.getOrderLength() == 1 && amount == 0) {
                                            Order.deleteOrderAt(index);
                                            promocodeStore.handleRemovePromo();
                                            Get.offAll(() => MenuScreen());
                                          } else {
                                            Order.deleteOrderAt(index);
                                            // Validate promocode after deletion
                                            promocodeStore.validatePromocodeOnCartChange();
                                          }
                                          _updatePrices();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(),
                                  child: Container(
                                    width: 22.w,
                                    height: 20.h,
                                    child: Text(
                                      orderItem['amount'] ?? '1',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Container(
                                    width: 24.w,
                                    height: 20.h,
                                    child: IconButton(
                                      icon: Icon(Icons.add, size: 14),
                                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          int amount = int.parse(orderItem['amount'] ?? '1');
                                          amount += 1;
                                          if (amount <= 10) {
                                            orderItem['amount'] = '$amount';
                                            // Validate promocode when quantity increases
                                            promocodeStore.validatePromocodeOnCartChange();
                                          }
                                          _updatePrices();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isPromoItem)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Подарок',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        // Updated delete button logic to match JSX
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isPromoItem) {
                                // SCENARIO 1: Bonus product deleted from basket
                                // → Remove promocode and ALL bonus products
                                // → Keep all regular products intact
                                print('Deleting bonus product - will remove promocode and all bonus products');
                                promocodeStore.handleRemovePromo();
                              } else {
                                // SCENARIO 2: Regular product deletion
                                // → Delete only this specific product
                                // → Validate if promocode conditions still met
                                print('Deleting regular product at index $index');
                                Order.deleteOrderAt(index);

                                // Validate promocode conditions after regular product deletion
                                promocodeStore.validatePromocodeOnCartChange();
                              }

                              // Check if cart becomes empty after any deletion
                              if (Order.getOrderLength() == 0) {
                                print('Cart is empty - clearing all promocode state');
                                promocodeStore.handleRemovePromo();
                                Get.offAll(() => MenuScreen());
                                return;
                              }

                              _updatePrices();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cWhite,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delete,
                              color: isPromoItem ? Colors.red : cDarkGreen,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );

    return result;
  }
}
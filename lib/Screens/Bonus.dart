import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:sushi_alpha_project/Consts/Widgets.dart';

import '../Backend/Api.dart';
import '../LocalMemory/User.dart';
import '../Localzition/locals.dart';

class BonusScreen extends StatelessWidget {
  const BonusScreen({super.key});

  /// Safely extract bonus amount from API response
  String _extractBonusAmount(dynamic data) {
    try {
      if (data == null) return '0';
      
      // If data is a Map, try to get the 'string' field
      if (data is Map) {
        var bonusValue = data['string'];
        
        // Handle nested Map
        if (bonusValue is Map) {
          return bonusValue['amount']?.toString() ?? '0';
        }
        
        // Handle String value
        if (bonusValue is String) {
          return bonusValue;
        }
        
        // Handle number value
        if (bonusValue is int || bonusValue is double) {
          return bonusValue.toString();
        }
        
        // Fallback: try direct conversion
        return bonusValue?.toString() ?? '0';
      }
      
      // If data is already a String
      if (data is String) {
        return data;
      }
      
      // If data is a number
      if (data is int || data is double) {
        return data.toString();
      }
      
      // Final fallback
      return data.toString();
    } catch (e) {
      print('❌ Error extracting bonus amount: $e');
      return '0';
    }
  }

  /// Format number with spaces (e.g., 121000 -> 121 000)
  String _formatAmount(String amount) {
    try {
      // Remove non-digits
      String digitsOnly = amount.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (digitsOnly.isEmpty) return '0';
      
      int number = int.parse(digitsOnly);
      
      // Format with spaces every 3 digits from right
      String formatted = '';
      String numberStr = number.toString();
      int length = numberStr.length;
      
      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          formatted += ' ';
        }
        formatted += numberStr[i];
      }
      
      return formatted;
    } catch (e) {
      return amount;
    }
  }

  /// Get tier widget based on order count
  Widget _buildTierCard(int orderCount) {
    String tierName;
    String discount;
    List<Color> gradientColors;
    IconData icon;

    if (orderCount >= 10) {
      tierName = "Gold";
      discount = "30%";
      icon = Icons.workspace_premium;
      gradientColors = [
        Color(0xffBF953F),
        Color(0xffFCF6BA),
        Color(0xffB38728),
      ];
    } else if (orderCount >= 5) {
      tierName = "Silver";
      discount = "20%";
      icon = Icons.military_tech;
      gradientColors = [
        Color(0xffa8a9ad),
        Color(0xffC0c0c3),
        Color(0xffe3e3e3),
      ];
    } else if (orderCount > 0) {
      tierName = "Bronze";
      discount = "10%";
      icon = Icons.stars;
      gradientColors = [
        Color(0xff6e3a06),
        Color(0xff9e5d1c),
        Color(0xffCd7f31),
      ];
    } else {
      // No tier yet
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        decoration: BoxDecoration(
          color: cGray,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: cDarkGreen.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 50.sp,
              color: cDarkGreen.withOpacity(0.5),
            ),
            SizedBox(height: 10.h),
            Text(
              "Сделайте первый заказ",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: cDarkGreen,
              ),
            ),
            Text(
              "чтобы получить статус",
              style: TextStyle(
                fontSize: 14.sp,
                color: cDarkGreen.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 60.sp,
            color: Colors.white,
          ),
          SizedBox(height: 15.h),
          Text(
            tierName,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: 5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Скидка $discount",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "Заказов: $orderCount",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: cWhite,
      appBar: AppBar(
        backgroundColor: cWhite, // Changed to white
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.navigate_before,
            color: cDarkGreen, // Changed to green
            size: 30,
          ),
        ),
        title: Text(
          LocaleData.bonuses.getString(context),
          style: TextStyle(
            fontSize: 25,
            color: cDarkGreen, // Changed to green
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.h),
                
                // Bonus Amount Section - FIXED
                FutureBuilder(
                  future: Api.getUserBonus(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: size.height * 0.5,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: cDarkGreen,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40.sp),
                            SizedBox(height: 10.h),
                            Text(
                              "Ошибка загрузки",
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${snapshot.error}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.red.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      // CRITICAL FIX: Safely extract bonus amount
                      String bonusAmount = _extractBonusAmount(snapshot.data);
                      
                      // Check for error message
                      if (bonusAmount.toLowerCase().contains("что-то пошло не так") ||
                          bonusAmount.toLowerCase().contains("error")) {
                        bonusAmount = "0";
                      }
                      
                      String formattedAmount = _formatAmount(bonusAmount);
                      
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cDarkGreen.withOpacity(0.1),
                              cDarkGreen.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: cDarkGreen.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: User.isUserExists() == false
                            ? Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: 50.sp,
                                    color: cDarkGreen,
                                  ),
                                  SizedBox(height: 15.h),
                                  Text(
                                    LocaleData.availablebonuses.getString(context),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: cDarkGreen.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "$formattedAmount ${LocaleData.som.getString(context)}",
                                    style: TextStyle(
                                      fontSize: 36.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Icon(
                                    Icons.account_circle_outlined,
                                    size: 50.sp,
                                    color: cDarkGreen.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 15.h),
                                  Text(
                                    LocaleData.youdonnothaveaccount.getString(context),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      color: cDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }
                  },
                ),
                
                SizedBox(height: 30.h),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

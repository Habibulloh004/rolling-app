import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../Localzition/locals.dart';
import '../../Consts/Colors.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the argument passed from the first screen
    final String receivedText = Get.arguments;

    void safeBack() {
      try {
        if (Get.isSnackbarOpen) {
          Get.closeCurrentSnackbar();
        }
      } catch (_) {}
      Navigator.of(context).maybePop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.navigate_before,
            size: 30,
            color: cDarkGreen,
          ),
          onPressed: safeBack,
        ),
        title: Text(LocaleData.news.getString(context)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          receivedText,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the argument passed from the first screen
    final String receivedText = Get.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('News')),
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

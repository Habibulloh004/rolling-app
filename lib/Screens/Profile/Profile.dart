import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';

import '../../Backend/Api.dart';
import '../../Consts/Functions.dart';
import '../../Consts/Widgets.dart';
import '../../LocalMemory/Boxes.dart';
import '../../LocalMemory/Language.dart';
import '../../LocalMemory/User.dart';
import '../../Localzition/locals.dart';
import '../../main.dart';
import '../Authentication/RegistrationScreen.dart';
import '../CreditCard/Cards.dart';
import 'Language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    bool doesHaveDateOfBirth = regex.hasMatch(User.getUserInfo("birthday"));
    return Scaffold(
      appBar: AppBar(
        leading: cGoBack(
          onPressed: () {
            Get.back();
          },
          color: cDarkGreen,
        ),
        title: Text(
          LocaleData.myprofile.getString(context),
          style: TextStyle(
            fontSize: 30,
            color: cDarkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(
                  LocaleData.name.getString(context),
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: cDarkGreen,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: cWhite, // Background color
                  borderRadius: BorderRadius.circular(10), // Border radius
                  border: Border.all(
                    color: cGray, // Border color
                    width: 2, // Border width
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        User.isKeyAvalible('name')
                            ? User.getUserInfo("name")
                            : "${LocaleData.youdonnothaveaccount.getString(context)}",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: cBlack,
                          fontWeight: FontWeight.w400,
                        )),
                    IconButton(
                        onPressed: () {
                          if (!User.isUserExists()) {
                            Get.defaultDialog(
                              title:
                                  "${LocaleData.writeyourname.getString(context)}",
                              titleStyle: TextStyle(fontSize: 24),
                              radius: 10,
                              content: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(height: 16),
                                    TextFormField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: cBlack, // Border color
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              10.0), // Border radius
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            width: 2.0, // Border width
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              10.0), // Border radius
                                        ),
                                        labelText:
                                            '${LocaleData.name.getString(context)}',
                                        labelStyle: TextStyle(color: cBlack),
                                      ),
                                    ),
                                    SizedBox(height: 16),
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
                                        onPressed: () {
                                          print(canUpdateProfile());

                                          if (canUpdateProfile()) {
                                            setState(() {
                                              // Api update name
                                              Api.updateUserName(
                                                  nameController.text);
                                              // Change local name
                                              User.addUserInfo(
                                                  "name", nameController.text);
                                              Get.back(); // This will close the dialog
                                            });
                                          } else {
                                            Get.snackbar(
                                              '${LocaleData.cooldown.getString(context)}', // title
                                              '', // message
                                              snackPosition: SnackPosition
                                                  .BOTTOM, // position
                                              backgroundColor: Colors.red,
                                              colorText: Colors.white,
                                              borderRadius: 20,
                                              margin: EdgeInsets.all(10),
                                              duration: Duration(
                                                  seconds: 4), // duration
                                            );
                                          }
                                        },
                                        child: Text(
                                          '${LocaleData.confirm.getString(context)}',
                                          style: TextStyle(color: cWhite),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              barrierDismissible:
                                  true, // Dialog will close when tapping outside
                            );
                          } else {
                            // you do not have account
                            Get.snackbar(
                              '${LocaleData.youdonnothaveaccount.getString(context)}', // title
                              '', // message
                              snackPosition: SnackPosition.BOTTOM, // position
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              borderRadius: 20,
                              margin: EdgeInsets.all(10),
                              duration: Duration(seconds: 4), // duration
                            );
                          }
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 20.sp,
                        ))
                  ],
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(
                  LocaleData.phonenumber.getString(context),
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: cDarkGreen,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: cWhite, // Background color
                  borderRadius: BorderRadius.circular(10), // Border radius
                  border: Border.all(
                    color: cGray, // Border color
                    width: 2, // Border width
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        User.isKeyAvalible('phone')
                            ? User.getUserInfo('phone')
                            : "${LocaleData.youdonnothaveaccount.getString(context)}",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: cBlack,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),

              //Age selekter
              !User.isUserExists()
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Text(
                            LocaleData.birthdate.getString(context),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: cDarkGreen,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: doesHaveDateOfBirth ? 10.h : 5.h),
                          decoration: BoxDecoration(
                            color: cWhite, // Background color
                            borderRadius:
                                BorderRadius.circular(10), // Border radius
                            border: Border.all(
                              color: cGray, // Border color
                              width: 2, // Border width
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  User.isKeyAvalible('birthday')
                                      ? User.getUserInfo("birthday")
                                      // we do not have the information
                                      : "${LocaleData.youdonnothaveaccount.getString(context)}",
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: cBlack,
                                    fontWeight: FontWeight.w400,
                                  )),
                              !doesHaveDateOfBirth
                                  ? IconButton(
                                      onPressed: () async {
                                        final pickedDate =
                                            await showModalBottomSheet<
                                                DateTime>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return BirthdatePicker(
                                              initialDate: selectedDate,
                                              onDateSelected: (DateTime date) {
                                                Navigator.pop(context, date);
                                              },
                                            );
                                          },
                                        );
                                        //'y-M-d'
                                        if (pickedDate != null) {
                                          setState(() {
                                            selectedDate = pickedDate;
                                            print(pickedDate);
                                            birthdateController.text =
                                                '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';

                                            //save localy
                                            Api.updateUserAge(
                                                birthdateController.text);
                                            User.addUserInfo("birthday",
                                                birthdateController.text);
                                          });
                                        }
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20.sp,
                                      ))
                                  : SizedBox()
                            ],
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 1.h,
                    ),

              // Gender
              !User.isUserExists()
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Text(
                            LocaleData.sex.getString(context),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: cDarkGreen,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: cWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cGray,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                User.isKeyAvalible('client_sex')
                                    ? User.getUserInfo("client_sex")
                                    : "${LocaleData.youdonnothaveaccount.getString(context)}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: cBlack,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled:
                                        true, // Allows for better resizing
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: 10.w,
                                          right: 10.w,
                                          bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom +
                                              10,
                                          top: 20.h,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GenderTextField(
                                              controller: genderController,
                                              initialGender: User.isKeyAvalible(
                                                      'client_sex')
                                                  ? User.getUserInfo(
                                                      "client_sex")
                                                  : "",
                                            ),
                                            SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: cDarkGreen,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  if (canUpdateProfile()) {
                                                    setState(() {
                                                      // Save gender to local storage or API
                                                      Api.updateUserGender(
                                                          getGendersForLanguage(
                                                                  Language
                                                                      .getLanguage())
                                                              .indexOf(
                                                                  genderController
                                                                      .text));
                                                      User.addUserInfo(
                                                          "client_sex",
                                                          genderController
                                                              .text);
                                                      Navigator.pop(
                                                          context); // Close the bottom sheet
                                                    });
                                                  } else {
                                                    Get.snackbar(
                                                      '${LocaleData.cooldown.getString(context)}', // title
                                                      '', // message
                                                      snackPosition: SnackPosition
                                                          .BOTTOM, // position
                                                      backgroundColor:
                                                          Colors.red,
                                                      colorText: Colors.white,
                                                      borderRadius: 20,
                                                      margin:
                                                          EdgeInsets.all(10),
                                                      duration: Duration(
                                                          seconds:
                                                              4), // duration
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  '${LocaleData.confirm.getString(context)}',
                                                  style:
                                                      TextStyle(color: cWhite),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.edit,
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 1.h,
                    ),

              Spacer(),

              User.isUserExists()
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle the button tap
                          // Get.to(() => LocationsScreen());
                          User.setLoginRegistrationFromProfile(true);
                          Get.offAll(() => RegistrationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 17.h),
                          backgroundColor: cDarkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                        ),
                        child: Text(
                          '${LocaleData.loginorregister.getString(context)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white, // Text color
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 10,
                    ),
              SizedBox(height: 15.h),

              SizedBox(height: 15.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle the button tap
                    Get.to(() => Cards());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 17.h),
                    backgroundColor: cDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: Text(
                    '${LocaleData.card.getString(context)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white, // Text color
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15.h),
              !User.isUserExists()
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle the button tap
                          Get.to(() => LanguageScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 17.h),
                          backgroundColor: cDarkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                        ),
                        child: Text(
                          '${LocaleData.language.getString(context)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white, // Text color
                          ),
                        ),
                      ),
                    )
                  : SizedBox(height: 15.h),
              SizedBox(height: 15.h),
              !User.isUserExists()
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.defaultDialog(
                                title: "",
                                titleStyle: TextStyle(fontSize: 20),
                                middleText:
                                    "${LocaleData.areyouherefirsttime.getString(context)}",
                                middleTextStyle: TextStyle(fontSize: 16),
                                radius: 5, // Радиус углов диалога
                                backgroundColor: Colors.white,
                                barrierDismissible:
                                    true, // Закрытие диалога при нажатии вне его
                                textCancel:
                                    "${LocaleData.cancel.getString(context)}",
                                cancelTextColor: Colors.black54,
                                textConfirm:
                                    "${LocaleData.confirm.getString(context)}",
                                confirmTextColor: Colors.white,
                                onCancel: () {
                                  // Navigator.pop(context);
                                },
                                onConfirm: () {
                                  clearBoxes();
                                  Get.offAll(() => SplashScreen());
                                },
                                buttonColor: cDarkGreen,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 17.h),
                              backgroundColor: cDarkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners
                              ),
                            ),
                            child: Text(
                              '${LocaleData.deleteaccount.getString(context)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15.h,
                        )
                      ],
                    )
                  : SizedBox(
                      height: 10,
                    ),

              // Log out
              !User.isUserExists()
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              clearBoxes();
                              Get.offAll(() => UpdateWrapper());
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 17.h),
                              backgroundColor: cDarkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners
                              ),
                            ),
                            child: Text(
                              '${LocaleData.logout.getString(context)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 10,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class BirthdatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const BirthdatePicker({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _BirthdatePickerState createState() => _BirthdatePickerState();
}

class _BirthdatePickerState extends State<BirthdatePicker> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDate.day;
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              LocaleData.selectYourBirthdate.getString(context),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPicker(
                      itemCount: 31,
                      selectedValue: selectedDay,
                      labelBuilder: (int index) => '$index',
                      onChanged: (value) => selectedDay = value,
                    ),
                    _buildPicker(
                      itemCount: 12,
                      selectedValue: selectedMonth,
                      labelBuilder: (int index) => '$index',
                      onChanged: (value) => selectedMonth = value,
                    ),
                    _buildPicker(
                      itemCount: 101,
                      selectedValue: selectedYear - (DateTime.now().year - 70),
                      labelBuilder: (int index) =>
                          '${DateTime.now().year - 70 + index}',
                      onChanged: (value) {
                        selectedYear = DateTime.now().year - 70 + value;
                      },
                    ),
                  ],
                ),
                // Highlighted middle area
                Center(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cDarkGreen.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cDarkGreen,
                foregroundColor: cWhite,
              ),
              onPressed: () {
                widget.onDateSelected(
                  DateTime(selectedYear, selectedMonth, selectedDay),
                );
              },
              child: Text(LocaleData.done.getString(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required int itemCount,
    required int selectedValue,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        physics: const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 1 || index > itemCount) return null;
            return Center(
              child: Text(
                labelBuilder(index),
                style: const TextStyle(fontSize: 24),
              ),
            );
          },
          childCount: itemCount + 1,
        ),
        onSelectedItemChanged: (value) {
          HapticFeedback.heavyImpact();
          if (value > 0 && value <= itemCount) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class GenderTextField extends StatefulWidget {
  final TextEditingController controller;
  final String initialGender;

  const GenderTextField({
    Key? key,
    required this.controller,
    this.initialGender = "", // Default initial value
  }) : super(key: key);

  @override
  _GenderTextFieldState createState() => _GenderTextFieldState();
}

class _GenderTextFieldState extends State<GenderTextField> {
  final List<String> genders = getGendersForLanguage(Language.getLanguage());
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set initial value in the controller if not already set
    if (widget.controller.text.isEmpty) {
      widget.controller.text = widget.initialGender;
      selectedIndex = genders.indexOf(widget.initialGender);
    } else {
      selectedIndex = genders.indexOf(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true, // Prevent manual editing
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cGray, width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelText: LocaleData.gender.getString(context),
        labelStyle: const TextStyle(color: cBlack),
        prefixIcon: const Icon(Icons.person),
      ),
      onTap: () async {
        final selectedGender = await showModalBottomSheet<String>(
          context: context,
          builder: (context) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          LocaleData.selectYourGender.getString(context),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView(
                          itemExtent: 50,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          children: genders.map((gender) {
                            return Center(
                              child: Text(
                                gender,
                                style: const TextStyle(fontSize: 24),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cDarkGreen,
                            foregroundColor: cWhite,
                          ),
                          onPressed: () {
                            Navigator.pop(context, genders[selectedIndex]);
                          },
                          child: Text(LocaleData.done.getString(context)),
                        ),
                      ),
                    ],
                  ),
                  // Highlighted middle area
                  Center(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      decoration: BoxDecoration(
                        color: cDarkGreen
                            .withOpacity(0.5), // Transparent highlight
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (selectedGender != null) {
          setState(() {
            widget.controller.text = selectedGender;
          });
        }
      },
    );
  }
}

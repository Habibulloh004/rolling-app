import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Backend/Api.dart';
import '../../Consts/Colors.dart';
import '../../Consts/Functions.dart';
import '../../LocalMemory/Language.dart';
import '../../Localzition/locals.dart';
import 'LoginScreen.dart';
import 'OTPScreen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  late DateTime selectedDate;
  final genderController = TextEditingController();
  bool passwordType = true;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); // Default initial date
  }

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
                            width: 300,
                            height: 100,
                            child: SvgPicture.asset(
                              "assets/images/LogoIcon.svg",
                            ),
                          ),
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
                                        '${LocaleData.registration.getString(context)}',
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: cDarkGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: cGray, // Border color
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
                                          prefixIcon: Icon(
                                            Icons.person,
                                            color: cBlack,
                                          ),
                                          labelStyle: TextStyle(color: cBlack),
                                        ),
                                        keyboardType: TextInputType.text,
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: phoneController,
                                        decoration: InputDecoration(
                                          prefix: Text("+998"),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: cGray, // Border color
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
                                              '${LocaleData.phonenumber.getString(context)}',
                                          prefixIcon: Icon(
                                            Icons.phone,
                                            color: cBlack,
                                          ),
                                          labelStyle: TextStyle(color: cBlack),
                                        ),
                                        keyboardType: TextInputType.phone,
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: passwordController,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: cGray, // Border color
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
                                          // filled: true,
                                          // fillColor: cGray,
                                          labelStyle: TextStyle(color: cBlack),
                                          labelText:
                                              '${LocaleData.password.getString(context)}',
                                          prefixIcon: Icon(
                                            Icons.lock,
                                            color: cBlack,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.visibility_off,
                                              color: cBlack,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                passwordType = !passwordType;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: passwordType,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      SizedBox(height: 20),
                                      TextFormField(
                                        controller: birthdateController,
                                        readOnly: true, // Prevent manual input
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: cGray, width: 2.0),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(width: 2.0),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          labelText:
                                              '${LocaleData.birthdate.getString(context)}',
                                          labelStyle: TextStyle(color: cBlack),
                                          prefixIcon: Icon(Icons.cake),
                                        ),
                                        onTap: () async {
                                          final pickedDate =
                                              await showModalBottomSheet<
                                                  DateTime>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return BirthdatePicker(
                                                initialDate: selectedDate,
                                                onDateSelected:
                                                    (DateTime date) {
                                                  Navigator.pop(context, date);
                                                },
                                              );
                                            },
                                          );

                                          if (pickedDate != null) {
                                            setState(() {
                                              selectedDate = pickedDate;
                                              birthdateController.text =
                                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                                            });
                                          }
                                        },
                                      ),
                                      SizedBox(height: 20),
                                      GenderTextField(
                                        controller: genderController,
                                        initialGender:
                                            '${LocaleData.gender.getString(context)}', // Optional, default is 'Male'
                                      ),
                                      SizedBox(height: 10),
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
                                            final pattern =
                                                r'^\+998[012345789]\d{8}$';
                                            final regExp = RegExp(pattern);

                                            if (nameController.text == "" ||
                                                genderController.text == "" ||
                                                phoneController.text == "" ||
                                                passwordController.text ==
                                                    " ") {
                                              print("Hello babu");
                                              // Get.snackbar(
                                              //   //make text that says fill information
                                              //   '${LocaleData..getString(context)}', // title
                                              //   '', // message
                                              //   snackPosition: SnackPosition
                                              //       .BOTTOM, // Display at the bottom
                                              //   backgroundColor: Colors.red,
                                              //   colorText: Colors.white,
                                              // );
                                            } else {
                                              if (!regExp.hasMatch("+998" +
                                                  phoneController.text)) {
                                                // If phone number doesn't match the pattern, show Get.snackbar
                                                Get.snackbar(
                                                  '${LocaleData.wrongphonenumber.getString(context)}', // title
                                                  '', // message
                                                  snackPosition: SnackPosition
                                                      .BOTTOM, // Display at the bottom
                                                  backgroundColor: Colors.red,
                                                  colorText: Colors.white,
                                                );
                                              } else {
                                                String code =
                                                    cGenerateRandomNumbers();
                                                Api.sendSms(
                                                    code,
                                                    "+998" +
                                                        phoneController.text);
                                                //Also give 3 controllers as data
                                                print(code);
                                                Map data = {
                                                  'from': 'register',
                                                  'phone': "+998" +
                                                      phoneController.text,
                                                  'name': nameController.text,
                                                  'password':
                                                      passwordController.text,
                                                  'code': code,
                                                  'client_sex':
                                                      getGendersForLanguage(
                                                              Language
                                                                  .getLanguage())
                                                          .indexOf(
                                                              genderController
                                                                  .text),
                                                  'birthday': convertDateToYMD(
                                                      birthdateController.text)

                                                  // ''
                                                };

                                                print(data);
                                                Get.to(() => OTPScreen(),
                                                    arguments: data);
                                              }
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 15),
                                            child: Text(
                                              '${LocaleData.createaccount.getString(context)}',
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
                                      SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  '${LocaleData.doyouhaveaccount.getString(context)}',
                                  style: TextStyle(
                                    color: cBlack,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.to(() => LoginScreen());
                                  },
                                  child: Text(
                                    '${LocaleData.login.getString(context)}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: cDarkGreen,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
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

String convertDateToYMD(String dateDMY) {
  try {
    // Parse the input date in d/m/y format
    DateTime parsedDate = DateFormat('d/M/y').parse(dateDMY);

    // Format the parsed date to y-m-d format
    String formattedDate = DateFormat('y-M-d').format(parsedDate);

    return formattedDate;
  } catch (e) {
    return 'Invalid date format';
  }
}

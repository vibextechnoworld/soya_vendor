// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, file_names

import 'package:flutter/material.dart';

//------------------Updated colors-----------------------//
Color primeryColor = const Color(0xFF43A047);
Color greenColor = const Color(0xFF43A047);
Color themeColor = const Color(0xFF43A047);
Color appColor = const Color(0xFF43A047);

Color bgcolor = whiteColor;
Color bg1Color = whiteColor.withOpacity(0.1);
Color gradientColor = const Color(0xFF43A047);
Color lightGreenColor = const Color(0xFFF5F9F6);
Color yelloColor = const Color.fromARGB(255, 255, 187, 13);
Color redColor = const Color.fromARGB(255, 255, 70, 70);
Color lightGrey = const Color(0xFFF5F5F5);
Color blackColor = const Color.fromARGB(255, 17, 19, 17);
Color black54 = const Color.fromARGB(255, 17, 19, 17).withOpacity(0.54);

Color whiteColor = Colors.white;
Color greyColor = const Color(0xFF757575);
Color greyColorOpacity2 = const Color(0xFF757575).withOpacity(0.2);
Color greyColorOpacity4 = const Color(0xFF757575).withOpacity(0.4);
Color greyColorOpacity6 = const Color(0xFF757575).withOpacity(0.6);
Color greyColorOpacity8 = const Color(0xFF757575).withOpacity(0.8);

//------------------------------------------//#1E61CC

class GradientColors {
  static Gradient btnGradient = LinearGradient(
    colors: [
      themeColor.withOpacity(0.85),
      themeColor.withOpacity(0.7),
      themeColor.withOpacity(0.5),
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const Gradient greenGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 255, 196, 40),
      Color.fromARGB(255, 255, 209, 42),
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const Gradient lightGradient = LinearGradient(
    colors: [Color(0xffdaedfd), Color(0xffdaedfd)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const Gradient transpharantGradient = LinearGradient(
    colors: [Colors.transparent, Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  //static const Color primeryColor = Color(0xff1EBC5D);
  static const Color primeryColor = Color.fromARGB(255, 30, 97, 204);

  static const Color blueLightColor = Colors.lightBlue;
}

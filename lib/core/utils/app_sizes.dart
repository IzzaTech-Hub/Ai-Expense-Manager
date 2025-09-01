import 'package:flutter/material.dart';

class AppSizes {
  static double width(double percentage) {
    // Return a reasonable default value
    return 300 * (percentage / 100);
  }

  static double height(double percentage) {
    // Return a reasonable default value
    return 600 * (percentage / 100);
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

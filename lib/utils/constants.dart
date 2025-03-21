
// Dynamic screen width
import 'package:flutter/material.dart';




double screenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

// Dynamic screen height
double screenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}